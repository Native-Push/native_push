#if os(iOS)
import Flutter
import UIKit
public typealias Application = UIApplication
#else
import FlutterMacOS
import Cocoa
public typealias Application = NSApplication
#endif
import UserNotifications

public class NativePushPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(name: "com.opdehipt.native_push", binaryMessenger: messenger)
        let instance = NativePushPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    let channel: FlutterMethodChannel
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task {
            do {
                switch call.method {
                case "registerForRemoteNotification":
                    result(try await registerForRemoteNotification())
                case "getNotificationToken":
                    result(getNotificationToken())
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
            catch {
                result(FlutterError(code: "native_push_error", message: nil, details: error))
            }
        }
    }
    
    public func application(_ application: Application, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.base64EncodedString()
        UserDefaults.standard.setValue(token, forKey: "native_push_remoteNotificationDeviceToken")
        channel.invokeMethod("newNotificationToken", arguments: token)
    }

    private func registerForRemoteNotification() async throws -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized:
            return true
        case .denied:
            return false
        default:
            await Application.shared.registerForRemoteNotifications()
            return try await UNUserNotificationCenter.current().requestAuthorization()
        }
    }

    private func getNotificationToken() -> String? {
        UserDefaults.standard.string(forKey: "native_push_remoteNotificationDeviceToken")
    }
}
