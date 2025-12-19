import SwiftUI

struct ShiftPlanView: View {
    @StateObject private var viewModel: ShiftPlanViewModel
    
    init(apiClient: DirectusAPIClient, userEmail: String?, bostedId: String) {
        _viewModel = StateObject(wrappedValue: ShiftPlanViewModel(apiClient: apiClient, userEmail: userEmail, bostedId: bostedId))
    }
    
    var body: some View {
        ZStack {
            // Background gradient matching Android
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0x37 / 255, green: 0x00 / 255, blue: 0xB3 / 255),
                    Color(red: 0x00 / 255, green: 0xBC / 255, blue: 0xD4 / 255),
                    Color(red: 0x62 / 255, green: 0x00 / 255, blue: 0xEE / 255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Main content card with purple background
                VStack(spacing: 0) {
                    // Header
                    Text("Medarbejdere i dag")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    
                    // Content
                    switch viewModel.shiftPlanState {
                    case .loading:
                        Spacer()
                        ProgressView("Henter vagtplan...")
                            .foregroundColor(.white)
                            .tint(.white)
                        Spacer()
                        
                    case .success(let shifts):
                        if shifts.isEmpty {
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                
                                Text("Ingen medarbejdere på vagt i dag")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Button("Genindlæs") {
                                    Task {
                                        await viewModel.retryLoading()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                            Spacer()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(shifts, id: \.id) { shift in
                                        ShiftCard(shift: shift)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                        }
                        
                    case .error(let message):
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            
                            Text("Kunne ikke hente vagtplandata")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(message)
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button("Prøv igen") {
                                Task {
                                    await viewModel.retryLoading()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
                        }
                        Spacer()
                    }
                }
                .background(
                    Color(red: 0x37 / 255, green: 0x00 / 255, blue: 0xB3 / 255)
                )
                .cornerRadius(24)
                .padding(.horizontal, 16)
            }
        }
    }
}

struct ShiftCard: View {
    let shift: Shift
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        Group {
            // Create a separate card for each assigned user (matching Android design)
            if let users = shift.assignedUsers, !users.isEmpty {
                ForEach(users, id: \.id) { user in
                    cardContent(userName: user.fullName, isEmptyCard: false)
                }
            } else {
                // No users assigned - show a single card
                cardContent(userName: "Ingen medarbejder tildelt", isEmptyCard: true)
            }
        }
    }
    
    @ViewBuilder
    private func cardContent(userName: String, isEmptyCard: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name at the top (bold, white)
            Text(userName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            // Time range (HH:mm format, light blue)
            if let start = shift.startDate, let end = shift.endDate {
                Text("\(Self.timeFormatter.string(from: start)) - \(Self.timeFormatter.string(from: end))")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0xBB / 255, green: 0xDE / 255, blue: 0xFB / 255))
            }
            
            // Sublocation with icon (yellow)
            if let subLocation = shift.subLocationName {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0xFF / 255, green: 0xEB / 255, blue: 0x3B / 255))
                    
                    Text(subLocation)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0xFF / 255, green: 0xEB / 255, blue: 0x3B / 255))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(red: 0x4A / 255, green: 0x14 / 255, blue: 0x8C / 255))
        .cornerRadius(12)
    }
}

#Preview {
    ShiftPlanView(
        apiClient: DirectusAPIClient(),
        userEmail: "test@example.com",
        bostedId: "test-bosted-id"
    )
}
