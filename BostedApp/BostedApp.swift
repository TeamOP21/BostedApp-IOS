import SwiftUI

@main
struct BostedAppMain: App {
    @StateObject private var loginViewModel: LoginViewModel
    
    init() {
        let apiClient = DirectusAPIClient()
        let authRepository = AuthRepository(apiClient: apiClient)
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepository))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(loginViewModel: loginViewModel)
        }
    }
}

struct ContentView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        if loginViewModel.isLoggedIn,
           let userEmail = loginViewModel.loggedInUserEmail,
           let bostedId = loginViewModel.bostedId {
            MainView(
                loginViewModel: loginViewModel,
                userEmail: userEmail,
                bostedId: bostedId,
                onLogout: {
                    loginViewModel.logout()
                }
            )
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}
