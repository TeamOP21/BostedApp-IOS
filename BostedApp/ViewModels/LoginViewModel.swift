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
    
    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    func login() async {
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
            } else {
                errorMessage = "Login mislykkedes"
            }
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Uventet fejl: \(error.localizedDescription)"
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
    }
}
