import SwiftUI

struct ShiftPlanView: View {
    @StateObject private var viewModel: ShiftPlanViewModel
    
    init(apiClient: DirectusAPIClient, userEmail: String?, bostedId: String) {
        _viewModel = StateObject(wrappedValue: ShiftPlanViewModel(apiClient: apiClient, userEmail: userEmail, bostedId: bostedId))
    }
    
    var body: some View {
        VStack {
            // Header
            Text("Vagtplan")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            // Content
            switch viewModel.shiftPlanState {
            case .loading:
                ProgressView("Henter vagtplan...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            case .success(let shifts):
                if shifts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Ingen vagter fundet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Der er ingen vagter planlagt for denne uge. Tjek senere for opdateringer.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button("Genindlæs") {
                            Task {
                                await viewModel.retryLoading()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(shifts, id: \.id) { shift in
                                ShiftCard(shift: shift)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Fejl ved hentning af vagtplan")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
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
            // Name at the top (bold)
            Text(userName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isEmptyCard ? .orange : .primary)
            
            // Time range (HH:mm format)
            if let start = shift.startDate, let end = shift.endDate {
                Text("\(Self.timeFormatter.string(from: start)) - \(Self.timeFormatter.string(from: end))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Sublocation with icon
            if let subLocation = shift.subLocationName {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    
                    Text(subLocation)
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    ShiftPlanView(
        apiClient: DirectusAPIClient(),
        userEmail: "test@example.com",
        bostedId: "test-bosted-id"
    )
}
