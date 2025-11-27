import SwiftUI

struct TopBarView: View {
    let onLogout: () -> Void
    @State private var showLogoutMenu = false
    @State private var showLogoutDialog = false
    @State private var currentTime = ""
    @State private var currentDate = ""
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // Date display on the left
            Text(currentDate)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black)
                .cornerRadius(24)
            
            Spacer()
            
            // Account button on the right
            Menu {
                Button(action: {
                    showLogoutDialog = true
                }) {
                    Label("Log ud", systemImage: "arrow.right.square")
                }
            } label: {
                Circle()
                    .fill(Color.black)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            updateDateTime()
        }
        .onReceive(timer) { _ in
            updateDateTime()
        }
        .alert("Log ud", isPresented: $showLogoutDialog) {
            Button("Annuller", role: .cancel) {}
            Button("Log ud", role: .destructive) {
                onLogout()
            }
        } message: {
            Text("Er du sikker på, at du vil logge ud?")
        }
    }
    
    private func updateDateTime() {
        let now = Date()
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "da_DK")
        dateFormatter.dateFormat = "EEEE, d. MMM"
        currentDate = dateFormatter.string(from: now).capitalized
    }
}
