import SwiftUI

struct MoreMenuPopup: View {
    let onToothbrushTapped: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Menu items
            VStack(spacing: 0) {
                // Toothbrush menu item
                Button(action: onToothbrushTapped) {
                    HStack(spacing: 16) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tandbørstning")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Husk at børste tænder")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(red: 0.22, green: 0, blue: 0.7))
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .padding(.bottom, 70) // Space for bottom navigation
        }
        .animation(.spring(response: 0.3), value: true)
    }
}

// Extension to support corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}