import SwiftUI

struct MoreView: View {
    let onNavigateToToothbrush: () -> Void
    let apiClient: DirectusAPIClient
    let userEmail: String
    let bostedId: String
    
    @State private var showToothbrushSheet = false
    @State private var showQRScannerFromSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Text("Mere")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
                .frame(height: 24)
            
            // Menu items
            ScrollView {
                VStack(spacing: 16) {
                    // Toothbrush menu item
                    MenuItemCard(
                        icon: "heart.text.square.fill",
                        title: "Tandbørstning",
                        subtitle: "Husk at børste tænder"
                    ) {
                        showToothbrushSheet = true
                    }
                    
                    Spacer()
                        .frame(height: 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showToothbrushSheet) {
            ToothbrushView(
                apiClient: apiClient,
                userEmail: userEmail,
                bostedId: bostedId,
                onDismiss: { showToothbrushSheet = false },
                shouldShowQRScanner: $showQRScannerFromSheet
            )
        }
    }
}

struct MenuItemCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(Color(red: 0.22, green: 0, blue: 0.7))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}