import SwiftUI

@main
struct BostedAppMain: App {
    @StateObject private var loginViewModel: LoginViewModel
    private let apiClient: DirectusAPIClient
    
    init() {
        let apiClient = DirectusAPIClient()
        let authRepository = AuthRepository(apiClient: apiClient)
        _loginViewModel = StateObject(wrappedValue: LoginViewModel(authRepository: authRepository))
        self.apiClient = apiClient
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(loginViewModel: loginViewModel, apiClient: apiClient)
        }
    }
}

struct ContentView: View {
    @ObservedObject var loginViewModel: LoginViewModel
    let apiClient: DirectusAPIClient
    
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
                }
            )
        } else {
            LoginView(viewModel: loginViewModel)
        }
    }
}
