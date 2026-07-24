import Flutter
import UIKit
import PushKit
import flutter_callkit_incoming
import UserNotifications
import AVFAudio
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.registerForRemoteNotifications()

    let mainQueue = DispatchQueue.main
    voipRegistry = PKPushRegistry(queue: mainQueue)
    voipRegistry?.delegate = self
    voipRegistry?.desiredPushTypes = [.voIP]

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    print("VoIP token: \(deviceToken)")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    print("VoIP token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    print("VoIP incoming push received: \(payload.dictionaryPayload)")
    guard type == .voIP else {
      completion()
      return
    }

    let payloadData = payload.dictionaryPayload
    let normalizedPayload = payloadData.reduce(into: [String: Any]()) { result, item in
      result["\(item.key)"] = item.value
    }
    let extra = normalizedPayload["extra"] as? [String: Any] ?? normalizedPayload

    let callId = stringValue(extra["call_id"])
      ?? stringValue(extra["callId"])
      ?? stringValue(normalizedPayload["id"])
      ?? UUID().uuidString
    let callerName = stringValue(extra["caller_name"])
      ?? stringValue(extra["callerName"])
      ?? stringValue(normalizedPayload["nameCaller"])
      ?? "Unknown"
    let handle = stringValue(extra["handle"]) ?? callerName
    let rawCallType = stringValue(extra["call_type"])
      ?? stringValue(extra["type"])
      ?? stringValue(normalizedPayload["callType"])
      ?? stringValue(normalizedPayload["type"])
      ?? "AUDIO"
    let isVideo = rawCallType.uppercased() == "VIDEO" || (normalizedPayload["isVideo"] as? Bool == true)

    let data = flutter_callkit_incoming.Data(
      id: callId,
      nameCaller: callerName,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    data.extra = extra as NSDictionary

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  private func stringValue(_ value: Any?) -> String? {
    guard let value = value else { return nil }
    let string = "\(value)"
    return string.isEmpty ? nil : string
  }

  func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  func onDecline(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  func onTimeOut(_ call: Call) {
  }

  func didActivateAudioSession(_ audioSession: AVAudioSession) {
  }

  func didDeactivateAudioSession(_ audioSession: AVAudioSession) {
  }
}
