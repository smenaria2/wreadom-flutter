import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.pluginRegistry.registrar(forPlugin: "ReaderPrivacy")!.messenger()
    let channel = FlutterMethodChannel(
      name: "in.wreadom.app/reader_privacy",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setSecureReader" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      let enabled = args?["enabled"] as? Bool ?? false
      self?.setReaderPrivacyOverlayEnabled(enabled)
      result(nil)
    }

    let hapticsChannel = FlutterMethodChannel(
      name: "in.wreadom.app/haptics",
      binaryMessenger: messenger
    )
    hapticsChannel.setMethodCallHandler { call, result in
      guard call.method == "impact" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      let type = args?["type"] as? String ?? "light"
      self.performNativeHaptic(type)
      result(nil)
    }
  }

  private func performNativeHaptic(_ type: String) {
    switch type {
    case "selection":
      let generator = UISelectionFeedbackGenerator()
      generator.prepare()
      generator.selectionChanged()
    case "medium":
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.prepare()
      generator.impactOccurred()
    default:
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      generator.impactOccurred()
    }
  }

  private func setReaderPrivacyOverlayEnabled(_ enabled: Bool) {
    guard let window = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow }) else {
      return
    }

    if enabled {
      if privacyOverlay == nil {
        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.systemBackground
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isHidden = true
        window.addSubview(overlay)
        privacyOverlay = overlay
      }
    } else {
      privacyOverlay?.removeFromSuperview()
      privacyOverlay = nil
    }
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    privacyOverlay?.isHidden = false
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    privacyOverlay?.isHidden = true
  }
}
