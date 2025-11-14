#if os(iOS)
import Flutter
import UIKit
public typealias Application = UIApplication
typealias LaunchOptions = UIScene.ConnectionOptions?
#else
import FlutterMacOS
import Cocoa
public typealias Application = NSApplication
typealias LaunchOptions = [AnyHashable : Any]
#endif
import UserNotifications

/// A plugin to handle native push notifications for Flutter applications.
public class NativePushPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {

    /// Registers the plugin with the Flutter registrar.
    /// - Parameter registrar: The Flutter plugin registrar.
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
        #if os(macOS)
        NativePushPlugin.channel = channel
        #endif
        UNUserNotificationCenter.current().delegate = instance
    }

    #if os(macOS)
    private static var channel: FlutterMethodChannel?

    /// Static method to handle new device token registration.
    /// - Parameter deviceToken: The device token for push notifications.
    public static func new(deviceToken: Data) {
        if let channel {
            new(deviceToken: deviceToken, channel: channel)
        }
    }

    /// Handles the application finish launching event.
    /// - Parameter notification: The launch notification.
    public func handleDidFinishLaunching(_ notification: Notification) {
        applicationStart(launchOptions: notification.userInfo ?? [:])
    }
    #endif

    /// Handles new device token registration and sends it to Flutter.
    /// - Parameters:
    ///   - deviceToken: The device token for push notifications.
    ///   - channel: The Flutter method channel.
    private static func new(deviceToken: Data, channel: FlutterMethodChannel) {
        let token = deviceToken.map { data in String(format: "%02.2hhx", data) }.joined()
        UserDefaults.standard.setValue(token, forKey: "native_push_remoteNotificationDeviceToken")
        Task {
            await MainActor.run {
                channel.invokeMethod("newNotificationToken", arguments: token)
            }
        }
    }

    /// Handles new notifications and sends them to Flutter.
    /// - Parameters:
    ///   - notification: The received notification.
    ///   - channel: The Flutter method channel.
    private static func new(notification: UNNotification, channel: FlutterMethodChannel) {
        Task {
            await MainActor.run {
                channel.invokeMethod("newNotification", arguments: transform(notification: notification.request.content.userInfo))
            }
        }
    }

    private let channel: FlutterMethodChannel
    private var initialNotification: [AnyHashable: Any]? = nil

    /// Initializes the plugin with a Flutter method channel.
    /// - Parameter channel: The Flutter method channel.
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    /// Handles method calls from Flutter.
    /// - Parameters:
    ///   - call: The Flutter method call.
    ///   - result: The result callback for the method call.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task {
            do {
                switch call.method {
                case "initialize":
                    #if os(macOS)
                    await initialize()
                    #endif
                    result("")
                case "getInitialNotification":
                    result(initialNotification)
                case "registerForRemoteNotification":
                    result(try await registerForRemoteNotification(call.arguments))
                case "getNotificationToken":
                    result(getNotificationToken())
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                result(FlutterError(code: "native_push_error", message: nil, details: error))
            }
        }
    }

    #if os(macOS)
    @objc
    #endif
    /// Called when the application successfully registers for remote notifications.
    /// - Parameters:
    ///   - application: The application instance.
    ///   - deviceToken: The device token for push notifications.
    public func application(_ application: Application, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NativePushPlugin.new(deviceToken: deviceToken, channel: channel)
    }

    /// Called when a notification is about to be presented.
    /// - Parameters:
    ///   - center: The notification center.
    ///   - notification: The notification to be presented.
    /// - Returns: The notification presentation options.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, macOS 11.0, *) {
            [.banner, .sound]
        } else {
            [.alert, .sound]
        }
    }

    /// Called when a notification response is received.
    /// - Parameters:
    ///   - center: The notification center.
    ///   - response: The notification response.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        NativePushPlugin.new(notification: response.notification, channel: channel)
    }

    /// Handles the application start event and processes any launch options.
    /// - Parameter launchOptions: The launch options.
    private func applicationStart(launchOptions: LaunchOptions) {
        #if os(iOS)
        let notification = launchOptions?.notificationResponse?.notification.request.content.userInfo
        #else
        let key = NSApplication.launchUserNotificationUserInfoKey
        let notification = launchOptions[key] as? [AnyHashable: Any]
        #endif
        if let notification {
            initialNotification = NativePushPlugin.transform(notification: notification)
        }
    }

    /// Transforms the notification content by removing unnecessary information.
    /// - Parameter notification: The notification content.
    /// - Returns: The transformed notification content.
    private static func transform(notification: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var userInfo = notification
        userInfo.removeValue(forKey: "aps")
        userInfo.removeValue(forKey: "native_push_image")
        return userInfo
    }

    #if os(macOS)
    /// Initializes the plugin on macOS and swaps method implementations.
    private func initialize() async {
        await MainActor.run {
            let appDelegate = NSApplication.shared.delegate
            let appDelegateClass: AnyClass? = object_getClass(appDelegate)

            let originalSelector = #selector(NSApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
            let swizzledSelector = #selector(NativePushPlugin.self.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

            if let swizzledMethod = class_getInstanceMethod(NativePushPlugin.self, swizzledSelector) {
                if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector) {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                } else {
                    class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
                }
            }
        }
    }
    #endif

    /// Registers the application for remote notifications.
    /// - Parameter arguments: The arguments from Flutter specifying notification options.
    /// - Returns: A boolean indicating successful registration.
    private func registerForRemoteNotification(_ arguments: Any?) async throws -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings()

        var allOptionsPresent = true
        var options: UNAuthorizationOptions = []
        if let argumentsList = arguments as? [String] {
            for argument in argumentsList {
                let optionPresent: Bool
                let option: UNAuthorizationOptions?
                switch argument {
                case "alert":
                    optionPresent = status.alertSetting == .enabled
                    option = .alert
                case "badge":
                    optionPresent = status.badgeSetting == .enabled
                    option = .badge
                case "sound":
                    optionPresent = status.soundSetting == .enabled
                    option = .sound
                #if os(iOS)
                case "carPlay":
                    optionPresent = status.carPlaySetting == .enabled
                    option = .carPlay
                #endif
                case "criticalAlert":
                    optionPresent = status.criticalAlertSetting == .enabled
                    option = .criticalAlert
                case "providesAppNotificationSettings":
                    optionPresent = status.providesAppNotificationSettings
                    option = .providesAppNotificationSettings
                case "provisional":
                    optionPresent = true
                    option = .provisional
                default:
                    optionPresent = true
                    option = nil
                    break
                }
                allOptionsPresent = allOptionsPresent && optionPresent
                if let option {
                    options.insert(option)
                }
            }
        }

        await Application.shared.registerForRemoteNotifications()
        switch status.authorizationStatus {
        case .denied:
            return false
        case .authorized:
            if !allOptionsPresent {
                fallthrough
            }
            return true
        default:
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        }
    }

    /// Retrieves the current notification token from user defaults.
    /// - Returns: The current notification token, if available.
    private func getNotificationToken() -> String? {
        UserDefaults.standard.string(forKey: "native_push_remoteNotificationDeviceToken")
    }
}

#if os(iOS)
extension NativePushPlugin: FlutterSceneLifeCycleDelegate {
    /// Handles the application finish launching event.
    /// - Parameters:
    ///   - application: The application instance.
    ///   - launchOptions: The launch options.
    /// - Returns: A boolean indicating successful launch.
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        applicationStart(launchOptions: connectionOptions)
        return true
    }
}
#endif
