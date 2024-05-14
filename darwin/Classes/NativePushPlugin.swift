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

public class NativePushPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {
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

    public static func new(deviceToken: Data) {
        if let channel {
            new(deviceToken: deviceToken, channel: channel)
        }
    }
    
    public func handleDidFinishLaunching(_ notification: Notification) {
        applicationStart(launchOptions: notification.userInfo ?? [:])
    }
    #else
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        applicationStart(launchOptions: launchOptions)
        return true
    }
    #endif
    

    private static func new(deviceToken: Data, channel: FlutterMethodChannel) {
        let token = deviceToken.map { data in String(format: "%02.2hhx", data) }.joined()
        UserDefaults.standard.setValue(token, forKey: "native_push_remoteNotificationDeviceToken")
        Task {
            await MainActor.run {
                channel.invokeMethod("newNotificationToken", arguments: token)
            }
        }
    }
    
    private static func new(notification: UNNotification, channel: FlutterMethodChannel) {
        Task {
            await MainActor.run {
                channel.invokeMethod("newNotification", arguments: transform(notification: notification.request.content.userInfo))
            }
        }
    }
    
    private let channel: FlutterMethodChannel
    private var initialNotification: [AnyHashable: Any]? = nil
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
    }

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
            }
            catch {
                result(FlutterError(code: "native_push_error", message: nil, details: error))
            }
        }
    }
    
    #if os(macOS)
    @objc
    #endif
    public func application(_ application: Application, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NativePushPlugin.new(deviceToken: deviceToken, channel: channel)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        if #available(iOS 14.0, macOS 11.0, *) {
            [.banner, .sound]
        } else {
            [.alert, .sound]
        }
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        NativePushPlugin.new(notification: response.notification, channel: channel)
    }
    
    private func applicationStart(launchOptions: [AnyHashable : Any]) {
        #if os(iOS)
        let key = UIApplication.LaunchOptionsKey.remoteNotification
        #else
        let key = NSApplication.launchUserNotificationUserInfoKey
        #endif
        if let notification = launchOptions[key] as? [AnyHashable: Any] {
            initialNotification = NativePushPlugin.transform(notification: notification)
        }
    }
    
    private static func transform(notification: [AnyHashable: Any]) -> [AnyHashable: Any] {
        var userInfo = notification
        userInfo.removeValue(forKey: "aps")
        userInfo.removeValue(forKey: "native_push_image")
        return userInfo
    }
    
    #if os(macOS)
    private func initialize() async {
        await MainActor.run {
            let appDelegate = NSApplication.shared.delegate
            let appDelegateClass: AnyClass? = object_getClass(appDelegate)

            let originalSelector = #selector(NSApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))
            let swizzledSelector = #selector(NativePushPlugin.self.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

            if let swizzledMethod = class_getInstanceMethod(NativePushPlugin.self, swizzledSelector) {
                if let originalMethod = class_getInstanceMethod(appDelegateClass, originalSelector)  {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                } else {
                    class_addMethod(appDelegateClass, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
                }
            }
        }
    }
    #endif

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

    private func getNotificationToken() -> String? {
        UserDefaults.standard.string(forKey: "native_push_remoteNotificationDeviceToken")
    }
}
