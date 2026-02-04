import SwiftUI

struct LogViewerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var logContent: String = ""
    @State private var autoRefresh = false
    @State private var timer: Timer?
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.38, green: 0, blue: 0.93)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Auto refresh toggle
                    HStack {
                        Text("Auto opdater")
                            .foregroundColor(.white)
                        Toggle("", isOn: $autoRefresh)
                            .onChange(of: autoRefresh) { _, enabled in 
                                if enabled {
                                    startAutoRefresh()
                                } else {
                                    stopAutoRefresh()
                                }
                            }
                    }
                    .padding()
                    
                    // Log content - NOW SELECTABLE!
                    ScrollView {
                        ScrollViewReader { proxy in
                            VStack(alignment: .leading, spacing: 0) {
                                Text(logContent.isEmpty ? "Ingen logs endnu..." : logContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .textSelection(.enabled) // ✅ NOW YOU CAN SELECT TEXT!
                                    .id("bottom")
                            }
                            .onChange(of: logContent) { _, _ in
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: refreshLog) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Opdater")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.22, green: 0, blue: 0.7))
                            .cornerRadius(12)
                        }
                        
                        Button(action: clearLog) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Ryd")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        
                        // ✅ NEW: COPY TO CLIPBOARD BUTTON
                        Button(action: copyToClipboard) {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Kopiér")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Copied confirmation
                    if showCopiedAlert {
                        Text("✅ Kopieret til clipboard!")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Luk") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                refreshLog()
            }
            .onDisappear {
                stopAutoRefresh()
            }
        }
    }
    
    private func refreshLog() {
        logContent = FileLogger.shared.getLogContent()
    }
    
    private func clearLog() {
        FileLogger.shared.clearLog()
        refreshLog()
    }
    
    // ✅ NEW: COPY ALL LOGS TO CLIPBOARD
    private func copyToClipboard() {
        let content = FileLogger.shared.getLogContent()
        UIPasteboard.general.string = content
        
        // Show confirmation
        withAnimation {
            showCopiedAlert = true
        }
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
    
    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            refreshLog()
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}