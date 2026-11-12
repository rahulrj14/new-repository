package app.lockin.lock_in

import java.nio.ByteBuffer
import java.security.SecureRandom
import java.util.UUID
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Encrypts every Bluetooth frame with AES-128-GCM. The 16-byte session key
 * only exists in the host's QR code, so nearby phones that never scanned it
 * can neither read nor forge frames. Uses only the platform's crypto.
 *
 * Wire format: nonce(12) | ciphertext | tag(16). The direction ("h" host→joiner,
 * "j" joiner→host) is bound in as associated data, so a frame can't be
 * reflected back at its sender.
 */
class FrameCrypto(sessionKey: ByteArray) {
    private val encKey = SecretKeySpec(hmac(sessionKey, "lockin-enc").copyOf(16), "AES")
    private val rng = SecureRandom()

    /** Per-session BLE service id: reveals nothing about who is hosting. */
    val serviceUuid: UUID = hmac(sessionKey, "lockin-adv").let {
        val b = ByteBuffer.wrap(it)
        UUID(b.long, b.long)
    }

    fun seal(plain: ByteArray, dir: String): ByteArray {
        val nonce = ByteArray(NONCE).also { rng.nextBytes(it) }
        val c = Cipher.getInstance("AES/GCM/NoPadding")
        c.init(Cipher.ENCRYPT_MODE, encKey, GCMParameterSpec(TAG_BITS, nonce))
        c.updateAAD(dir.toByteArray())
        return nonce + c.doFinal(plain)
    }

    /** Returns null for anything not sealed with this session's key. */
    fun open(data: ByteArray, dir: String): ByteArray? {
        if (data.size < NONCE + TAG_BITS / 8) return null
        return try {
            val c = Cipher.getInstance("AES/GCM/NoPadding")
            c.init(Cipher.DECRYPT_MODE, encKey, GCMParameterSpec(TAG_BITS, data, 0, NONCE))
            c.updateAAD(dir.toByteArray())
            c.doFinal(data, NONCE, data.size - NONCE)
        } catch (_: AEADBadTagException) {
            null
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        private const val NONCE = 12
        private const val TAG_BITS = 128

        private fun hmac(key: ByteArray, label: String): ByteArray {
            val mac = Mac.getInstance("HmacSHA256")
            mac.init(SecretKeySpec(key, "HmacSHA256"))
            return mac.doFinal(label.toByteArray())
        }
    }
}
