import Flutter
import LocalAuthentication
import UIKit

/// Streams raw device-use signals to Dart and toggles face-down mode.
///
/// Everything here is on-device. Nothing is stored or sent anywhere.
final class DeviceUseMonitor: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  /// Events that happen before Dart starts listening are buffered.
  private var buffer: [[String: Any]] = []
  private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
  private var faceDownMode = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = DeviceUseMonitor()
    let methods = FlutterMethodChannel(
      name: "lockin/device_use", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: methods)
    let events = FlutterEventChannel(
      name: "lockin/device_use/events", binaryMessenger: registrar.messenger())
    events.setStreamHandler(instance)
    instance.startObserving()
  }

  // MARK: - Observing

  private func startObserving() {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let nc = NotificationCenter.default
    let pairs: [(Notification.Name, String)] = [
      (UIApplication.didBecomeActiveNotification, "appActive"),
      (UIApplication.willResignActiveNotification, "appInactive"),
      (UIApplication.didEnterBackgroundNotification, "appBackground"),
      (UIApplication.willEnterForegroundNotification, "appForeground"),
      (UIApplication.protectedDataWillBecomeUnavailableNotification, "deviceLocked"),
      (UIApplication.protectedDataDidBecomeAvailableNotification, "deviceUnlocked"),
      (UIDevice.batteryLevelDidChangeNotification, "battery"),
    ]
    for (name, signal) in pairs {
      nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.onSystem(signal)
      }
    }
    nc.addObserver(
      forName: UIDevice.proximityStateDidChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.emit(UIDevice.current.proximityState ? "proximityCovered" : "proximityUncovered")
    }
  }

  private func onSystem(_ signal: String) {
    switch signal {
    case "appInactive", "appBackground":
      // Keep the Dart side alive briefly so the 10 s grace window can be
      // judged in real time when someone switches apps. iOS allows this
      // for short tasks; it does not keep the app running indefinitely.
      beginGraceBackgroundTask()
    case "appActive":
      endGraceBackgroundTask()
    default:
      break
    }
    emit(signal)
  }

  private func beginGraceBackgroundTask() {
    guard backgroundTask == .invalid else { return }
    backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "lockin.grace") {
      [weak self] in
      self?.emit("backgroundTimeExpired")
      self?.endGraceBackgroundTask()
    }
    // Release well before iOS would force it: the grace window is 10 s.
    DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
      self?.endGraceBackgroundTask()
    }
  }

  private func endGraceBackgroundTask() {
    guard backgroundTask != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTask)
    backgroundTask = .invalid
  }

  private func emit(_ signal: String) {
    let event: [String: Any] = [
      "signal": signal,
      "t": Int(Date().timeIntervalSince1970 * 1000),
      "battery": Double(UIDevice.current.batteryLevel),
    ]
    if let sink = sink {
      sink(event)
    } else {
      buffer.append(event)
    }
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    buffer.forEach { events($0) }
    buffer.removeAll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  // MARK: - Methods

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setFaceDownMode":
      let on = (call.arguments as? Bool) ?? false
      faceDownMode = on
      // Proximity monitoring turns the screen off when the sensor is covered;
      // the idle timer must be off or iOS auto-locks after a few minutes.
      UIDevice.current.isProximityMonitoringEnabled = on
      UIApplication.shared.isIdleTimerDisabled = on
      result(UIDevice.current.isProximityMonitoringEnabled == on)
    case "snapshot":
      let app = UIApplication.shared
      let state: String
      switch app.applicationState {
      case .active: state = "active"
      case .inactive: state = "inactive"
      case .background: state = "background"
      @unknown default: state = "unknown"
      }
      result([
        "platform": "ios",
        "protectedDataAvailable": app.isProtectedDataAvailable,
        "proximityCovered": UIDevice.current.proximityState,
        "proximitySupported": proximitySupported(),
        "passcodeSet": LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil),
        "battery": Double(UIDevice.current.batteryLevel),
        "appState": state,
        "model": UIDevice.current.model,
        "system": "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)",
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func proximitySupported() -> Bool {
    let device = UIDevice.current
    let was = device.isProximityMonitoringEnabled
    device.isProximityMonitoringEnabled = true
    let supported = device.isProximityMonitoringEnabled
    device.isProximityMonitoringEnabled = was
    return supported
  }
}
