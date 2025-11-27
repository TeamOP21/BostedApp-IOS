import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("Log ind")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 32)
            
            // Email field
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            // Password field
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Spacer()
                .frame(height: 32)
            
            // Login button
            Button(action: {
                Task {
                    await viewModel.login()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log ind")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 50)
            .background(Color.blue)
            .cornerRadius(8)
            .padding(.horizontal)
            .disabled(viewModel.isLoading)
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}
