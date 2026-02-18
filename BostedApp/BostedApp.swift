import SwiftUI
import SwiftData
import UserNotifications

@main
struct BostedAppMain: App {
    @StateObject private var loginViewModel: LoginViewModel
    @StateObject private var notificationDelegate = NotificationDelegate()
    private let apiClient: DirectusAPIClient
    
    init() {
        let apiClient = DirectusAPIClient()
        let authRepository = AuthRepository(apiClient: apiClient)
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepository))
        self.apiClient = apiClient
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                loginViewModel: loginViewModel,
                apiClient: apiClient,
                notificationDelegate: notificationDelegate
            )
        }
        .modelContainer(for: [Medicine.self, Reminder.self, ToothbrushReminder.self])
    }
}

struct ContentView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    let apiClient: DirectusAPIClient
    @ObservedObject var notificationDelegate: NotificationDelegate
    
    var body: some View {
        if loginViewModel.isLoggedIn,
           let userEmail = loginViewModel.loggedInUserEmail,
           let bostedId = loginViewModel.bostedId {
            MainView(
                apiClient: apiClient,
                loginViewModel: loginViewModel,
                userEmail: userEmail,
                bostedId: bostedId,
                onLogout: {
                    loginViewModel.logout()
                },
                notificationDelegate: notificationDelegate
            )
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}

// Notification Delegate to handle notification taps
class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var shouldShowToothbrushScanner = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
        
        let userInfo = notification.request.content.userInfo
        let identifier = notification.request.identifier
        
        // If this is the MAIN toothbrush notification (not a repeat), reschedule today's repeats
        if let type = userInfo["type"] as? String, type == "toothbrush",
           !identifier.contains("_repeat_"),
           let reminderId = userInfo["reminderId"] as? String,
           let hour = userInfo["hour"] as? Int,
           let minute = userInfo["minute"] as? Int {
            FileLogger.shared.log("🪥 Main toothbrush notification fired in foreground – rescheduling today's repeats for \(reminderId)", level: .info)
            Task {
                await NotificationManager.shared.scheduleToothbrushTodayRepeats(
                    id: reminderId,
                    hour: hour,
                    minute: minute
                )
            }
        }
    }
    
    // Handle notification tap when user taps on it
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let identifier = response.notification.request.identifier
        
        FileLogger.shared.log("🔔 Notification tapped: \(userInfo)", level: .info)
        
        // Check if it's a toothbrush notification
        if let type = userInfo["type"] as? String, type == "toothbrush" {
            FileLogger.shared.log("🪥 Toothbrush notification tapped - showing QR scanner", level: .info)
            
            // If this is the MAIN notification, reschedule today's repeats
            // (handles case where app was in background when main notification fired)
            if !identifier.contains("_repeat_"),
               let reminderId = userInfo["reminderId"] as? String,
               let hour = userInfo["hour"] as? Int,
               let minute = userInfo["minute"] as? Int {
                Task {
                    await NotificationManager.shared.scheduleToothbrushTodayRepeats(
                        id: reminderId,
                        hour: hour,
                        minute: minute
                    )
                }
            }
            
            // Trigger showing the QR scanner
            DispatchQueue.main.async {
                self.shouldShowToothbrushScanner = true
            }
        }
        
        completionHandler()
    }
}
