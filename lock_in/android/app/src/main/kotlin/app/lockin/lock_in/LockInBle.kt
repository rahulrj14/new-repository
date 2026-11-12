package app.lockin.lock_in

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.os.PowerManager
import io.flutter.plugin.common.EventChannel
import java.util.ArrayDeque
import java.util.UUID

/**
 * Bluetooth LE for squads. The host is a GATT server advertising a
 * per-session service id (derived from the QR key); joiners scan for that
 * exact id, connect, and talk over two characteristics:
 *   control (joiner → host, write) and events (host → joiner, notify).
 * Every frame is AES-GCM encrypted (see FrameCrypto). No pairing, no
 * location, no names in the air. Runs only while a squad is active.
 *
 * Permissions are checked by MainActivity.prepare() before any call here.
 */
@SuppressLint("MissingPermission")
object LockInBle : EventChannel.StreamHandler {
    private val CONTROL: UUID = UUID.fromString("6c6f636b-696e-4001-8000-00805f9b34fb")
    private val EVENTS: UUID = UUID.fromString("6c6f636b-696e-4002-8000-00805f9b34fb")
    private val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    private val main = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null
    private lateinit var ctx: Context
    private var crypto: FrameCrypto? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // Host side.
    private var server: BluetoothGattServer? = null
    private var eventsChar: BluetoothGattCharacteristic? = null
    private val devices = HashMap<String, BluetoothDevice>()
    private val notifyQueue = ArrayDeque<Pair<String, ByteArray>>()
    private var notifyBusy = false
    private var advertising = false

    // Joiner side.
    private var gatt: BluetoothGatt? = null
    private var controlChar: BluetoothGattCharacteristic? = null
    private val writeQueue = ArrayDeque<ByteArray>()
    private var writeBusy = false
    private var joining = false
    private var scanning = false

    fun init(context: Context) {
        ctx = context.applicationContext
    }

    private val manager get() = ctx.getSystemService(BluetoothManager::class.java)

    // ------------------------------------------------------------- events

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emit(vararg pairs: Pair<String, Any?>) {
        val m = mapOf(*pairs)
        main.post { sink?.success(m) }
    }

    private fun fail(reason: String) = emit("type" to "failed", "reason" to reason)

    // --------------------------------------------------------------- host

    fun startHost(key: ByteArray) {
        stop()
        val adapter = manager?.adapter
        if (adapter == null) return fail("unsupported")
        if (!adapter.isEnabled) return fail("bluetooth_off")
        val c = FrameCrypto(key)
        crypto = c
        holdWakeLock()
        val srv = manager.openGattServer(ctx, serverCallback) ?: return fail("advertise_failed")
        server = srv
        val service = BluetoothGattService(c.serviceUuid, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        val control = BluetoothGattCharacteristic(
            CONTROL,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        val ev = BluetoothGattCharacteristic(
            EVENTS,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ,
        )
        ev.addDescriptor(
            BluetoothGattDescriptor(CCCD, BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE),
        )
        service.addCharacteristic(control)
        service.addCharacteristic(ev)
        eventsChar = ev
        srv.addService(service) // advertising starts in onServiceAdded
    }

    private fun startAdvertising() {
        val c = crypto ?: return
        val adv = manager?.adapter?.bluetoothLeAdvertiser ?: return fail("advertise_failed")
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_MEDIUM)
            .setConnectable(true)
            .setTimeout(0)
            .build()
        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(c.serviceUuid))
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .build()
        adv.startAdvertising(settings, data, advertiseCallback)
        advertising = true
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartFailure(errorCode: Int) {
            advertising = false
            fail("advertise_failed")
        }
    }

    fun stopAdvertising() {
        if (!advertising) return
        manager?.adapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
        advertising = false
    }

    private val serverCallback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService) {
            main.post { if (status == BluetoothGatt.GATT_SUCCESS) startAdvertising() else fail("advertise_failed") }
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            main.post {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    devices[device.address] = device
                    emit("type" to "connected", "peer" to device.address)
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    devices.remove(device.address)
                    emit("type" to "disconnected", "peer" to device.address)
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice, requestId: Int, characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?,
        ) {
            if (responseNeeded) server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            if (characteristic.uuid != CONTROL || value == null) return
            val plain = crypto?.open(value, "j") ?: return
            emit("type" to "frame", "peer" to device.address, "bytes" to plain)
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int, descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean, offset: Int, value: ByteArray?,
        ) {
            if (responseNeeded) server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            main.post {
                notifyBusy = false
                pumpNotify()
            }
        }
    }

    private fun pumpNotify() {
        if (notifyBusy) return
        val srv = server ?: return
        val ch = eventsChar ?: return
        while (notifyQueue.isNotEmpty()) {
            val (peer, value) = notifyQueue.removeFirst()
            val device = devices[peer] ?: continue
            notifyBusy = true
            val ok = if (Build.VERSION.SDK_INT >= 33) {
                srv.notifyCharacteristicChanged(device, ch, false, value) == BluetoothGatt.GATT_SUCCESS
            } else {
                @Suppress("DEPRECATION")
                ch.value = value
                @Suppress("DEPRECATION")
                srv.notifyCharacteristicChanged(device, ch, false)
            }
            if (!ok) {
                notifyBusy = false
                continue
            }
            // Never stall if a callback goes missing.
            main.postDelayed({ if (notifyBusy) { notifyBusy = false; pumpNotify() } }, 1000)
            return
        }
    }

    // ------------------------------------------------------------- joiner

    fun startJoin(key: ByteArray) {
        stop()
        val adapter = manager?.adapter
        if (adapter == null) return fail("unsupported")
        if (!adapter.isEnabled) return fail("bluetooth_off")
        crypto = FrameCrypto(key)
        joining = true
        holdWakeLock()
        scan()
    }

    private fun scan() {
        val c = crypto ?: return
        if (!joining || scanning) return
        val scanner = manager?.adapter?.bluetoothLeScanner ?: return fail("scan_failed")
        val filter = ScanFilter.Builder().setServiceUuid(ParcelUuid(c.serviceUuid)).build()
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        scanner.startScan(listOf(filter), settings, scanCallback)
        scanning = true
    }

    private fun stopScan() {
        if (!scanning) return
        manager?.adapter?.bluetoothLeScanner?.stopScan(scanCallback)
        scanning = false
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            main.post {
                if (!joining || gatt != null) return@post
                stopScan()
                gatt = result.device.connectGatt(ctx, false, gattCallback, BluetoothDevice.TRANSPORT_LE)
            }
        }

        override fun onScanFailed(errorCode: Int) {
            scanning = false
            fail("scan_failed")
        }
    }

    private val gattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            main.post {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    // Room for nonce + frame + tag in one packet.
                    if (!g.requestMtu(185)) g.discoverServices()
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    g.close()
                    if (gatt == g) gatt = null
                    controlChar = null
                    writeQueue.clear()
                    writeBusy = false
                    emit("type" to "disconnected", "peer" to "host")
                    // Out of range or host app hiccup: keep trying while in a squad.
                    if (joining) main.postDelayed({ scan() }, 2000)
                }
            }
        }

        override fun onMtuChanged(g: BluetoothGatt, mtu: Int, status: Int) {
            main.post { g.discoverServices() }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            main.post {
                val service = crypto?.let { g.getService(it.serviceUuid) }
                val ev = service?.getCharacteristic(EVENTS)
                controlChar = service?.getCharacteristic(CONTROL)
                if (ev == null || controlChar == null) {
                    g.disconnect()
                    return@post
                }
                g.setCharacteristicNotification(ev, true)
                val d = ev.getDescriptor(CCCD)
                if (Build.VERSION.SDK_INT >= 33) {
                    g.writeDescriptor(d, BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)
                } else {
                    @Suppress("DEPRECATION")
                    d.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
                    @Suppress("DEPRECATION")
                    g.writeDescriptor(d)
                }
            }
        }

        override fun onDescriptorWrite(g: BluetoothGatt, descriptor: BluetoothGattDescriptor, status: Int) {
            main.post {
                emit("type" to "connected", "peer" to "host")
                pumpWrite()
            }
        }

        override fun onCharacteristicChanged(g: BluetoothGatt, ch: BluetoothGattCharacteristic, value: ByteArray) {
            onNotify(ch, value)
        }

        @Deprecated("API < 33")
        override fun onCharacteristicChanged(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
            @Suppress("DEPRECATION")
            if (Build.VERSION.SDK_INT < 33) onNotify(ch, ch.value ?: return)
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, ch: BluetoothGattCharacteristic, status: Int) {
            main.post {
                writeBusy = false
                pumpWrite()
            }
        }
    }

    private fun onNotify(ch: BluetoothGattCharacteristic, value: ByteArray) {
        if (ch.uuid != EVENTS) return
        val plain = crypto?.open(value, "h") ?: return
        emit("type" to "frame", "peer" to "host", "bytes" to plain)
    }

    private fun pumpWrite() {
        if (writeBusy) return
        val g = gatt ?: return
        val ch = controlChar ?: return
        val value = writeQueue.pollFirst() ?: return
        writeBusy = true
        val ok = if (Build.VERSION.SDK_INT >= 33) {
            g.writeCharacteristic(ch, value, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT) == BluetoothGatt.GATT_SUCCESS
        } else {
            @Suppress("DEPRECATION")
            ch.value = value
            ch.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
            @Suppress("DEPRECATION")
            g.writeCharacteristic(ch)
        }
        if (!ok) {
            writeBusy = false
            main.postDelayed({ pumpWrite() }, 100)
            return
        }
        main.postDelayed({ if (writeBusy) { writeBusy = false; pumpWrite() } }, 1500)
    }

    // ------------------------------------------------------------- shared

    fun send(peer: String, plain: ByteArray) {
        val c = crypto ?: return
        if (peer == "host") {
            writeQueue.addLast(c.seal(plain, "j"))
            pumpWrite()
        } else {
            notifyQueue.addLast(peer to c.seal(plain, "h"))
            pumpNotify()
        }
    }

    fun disconnect(peer: String) {
        val d = devices[peer] ?: return
        server?.cancelConnection(d)
    }

    fun stop() {
        joining = false
        stopScan()
        stopAdvertising()
        gatt?.let {
            it.disconnect()
            it.close()
        }
        gatt = null
        controlChar = null
        writeQueue.clear()
        writeBusy = false
        server?.close()
        server = null
        eventsChar = null
        devices.clear()
        notifyQueue.clear()
        notifyBusy = false
        crypto = null
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    /** Keeps the CPU awake during a squad so heartbeats keep flowing. */
    private fun holdWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = ctx.getSystemService(PowerManager::class.java)
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "lockin:squad").also {
            it.acquire(4 * 60 * 60 * 1000L)
        }
    }
}
