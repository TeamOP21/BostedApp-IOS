import SwiftUI

struct ShiftPlanView: View {
    @ObservedObject var viewModel: ShiftPlanViewModel
    let onLogout: () -> Void
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0, blue: 0.7),  // #3700B3
                    Color(red: 0, green: 0.74, blue: 0.83), // #00BCD4
                    Color(red: 0.38, green: 0, blue: 0.93)  // #6200EE
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                TopBarView(onLogout: onLogout)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Main content
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.22, green: 0, blue: 0.7))
                    .overlay(
                        contentView
                    )
                    .padding(16)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medarbejdere i dag")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
            
            switch viewModel.shiftPlanState {
            case .loading:
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
                
            case .success(let shifts):
                if shifts.isEmpty {
                    Spacer()
                    Text("Ingen medarbejdere på vagt i dag")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(shifts) { shift in
                                ShiftItemView(shift: shift)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
            case .error(let message):
                Spacer()
                VStack(spacing: 16) {
                    Text("Kunne ikke hente vagtplandata")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        Task {
                            await viewModel.retryLoading()
                        }
                    }) {
                        Text("Prøv igen")
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
    }
}

struct ShiftItemView: View {
    let shift: Shift
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(shift.assignedUsers ?? [], id: \.id) { user in
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(formatTime(shift.startDateTime)) - \(formatTime(shift.endDateTime))")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.73, green: 0.87, blue: 0.98))
                    
                    if let location = shift.subLocationName {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                            Text(location)
                                .font(.subheadline)
                        }
                        .foregroundColor(Color(red: 1, green: 0.92, blue: 0.23))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(red: 0.29, green: 0.08, blue: 0.55))
                .cornerRadius(12)
            }
        }
    }
    
    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "da_DK")
        return timeFormatter.string(from: date)
    }
}
