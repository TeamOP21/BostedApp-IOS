import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    @Published var loggedInUserEmail: String?
    @Published var bostedId: String?
    
    private let authRepository: AuthRepository
    private var cancellables = Set<AnyCancellable>()
    
    // Hardcoded credentials for automatic login (matching Android app)
    private let adminEmail = "admin@team-op.dk"
    private let adminPassword = "Teamop21"
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        // Attempt automatic login on initialization
        Task {
            await attemptAutoLogin()
        }
    }
    
    /// Attempt automatic login with hardcoded credentials
    private func attemptAutoLogin() async {
        // Only attempt auto-login if not already logged in
        if !isLoggedIn {
            await loginWithCredentials(email: adminEmail, password: adminPassword)
        }
    }
    
    func login() async {
        await loginWithCredentials(email: email, password: password)
    }
    
    private func loginWithCredentials(email: String, password: String) async {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Indtast venligst email og adgangskode"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = try await authRepository.login(email: email, password: password)
            
            if success {
                // Store credentials
                loggedInUserEmail = email
                bostedId = "1" // Default bosted ID
                isLoggedIn = true
                print("✅ Login successful! User: \(email)")
            } else {
                errorMessage = "Login mislykkedes"
                print("❌ Login failed: Invalid credentials")
            }
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
            print("❌ Login failed with AuthError: \(error.localizedDescription)")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
            print("❌ Login failed with APIError: \(error.localizedDescription)")
        } catch {
            errorMessage = "Uventet fejl: \(error.localizedDescription)"
            print("❌ Login failed with unexpected error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func logout() {
        isLoggedIn = false
        loggedInUserEmail = nil
        bostedId = nil
        email = ""
        password = ""
        errorMessage = nil
        print("👋 User logged out")
    }
}
