import SwiftUI
import SwiftData
import AVFoundation

struct ToothbrushView: View {
    let apiClient: DirectusAPIClient
    let userEmail: String
    let bostedId: String
    let onDismiss: () -> Void
    @Binding var shouldShowQRScanner: Bool
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ToothbrushViewModel
    @State private var showAddDialog = false
    @State private var showQRScanner = false
    @State private var showSuccessToast = false
    @State private var successMessage = ""
    
    init(apiClient: DirectusAPIClient, userEmail: String, bostedId: String, onDismiss: @escaping () -> Void, shouldShowQRScanner: Binding<Bool>) {
        self.apiClient = apiClient
        self.userEmail = userEmail
        self.bostedId = bostedId
        self.onDismiss = onDismiss
        self._shouldShowQRScanner = shouldShowQRScanner
        
        // Note: We'll need to pass modelContext after init
        // For now, we'll initialize it in the body
        _viewModel = StateObject(wrappedValue: ToothbrushViewModel(modelContext: ModelContext(ModelContainer.shared)))
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0, blue: 0.7),
                    Color(red: 0, green: 0.74, blue: 0.83),
                    Color(red: 0.38, green: 0, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Tandbørstning")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showAddDialog = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                    .frame(height: 24)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        switch viewModel.uiState {
                        case .loading:
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding()
                            
                        case .success(let reminders):
                            if reminders.isEmpty {
                                NoRemindersView()
                            } else {
                                ForEach(reminders, id: \.id) { reminder in
                                    ToothbrushReminderCard(
                                        reminder: reminder,
                                        onToggle: { enabled in
                                            viewModel.toggleReminderEnabled(id: reminder.id, enabled: enabled)
                                        },
                                        onDelete: {
                                            viewModel.deleteReminder(id: reminder.id)
                                        }
                                    )
                                }
                            }
                            
                        case .error(let message):
                            ErrorView(message: message)
                        }
                        
                        Spacer()
                            .frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .sheet(isPresented: $showAddDialog) {
            AddToothbrushReminderView(
                onAdd: { hour, minute in
                    viewModel.addReminder(hour: hour, minute: minute)
                    showAddDialog = false
                },
                onCancel: { showAddDialog = false }
            )
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            QRScannerView(
                onScan: { code in
                    handleQRCode(code)
                    showQRScanner = false
                },
                onCancel: { showQRScanner = false }
            )
        }
        .onAppear {
            // Note: modelContext is available here but ToothbrushViewModel is initialized in init()
            // with ModelContainer.shared. This is a known limitation.
            _ = ToothbrushViewModel(modelContext: modelContext)
        }
        .onChange(of: shouldShowQRScanner) { _, newValue in
            if newValue {
                // Show the QR scanner
                showQRScanner = true
                // Reset the binding
                shouldShowQRScanner = false
            }
        }
        .overlay(alignment: .bottom) {
            if showSuccessToast {
                ToastView(message: successMessage)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSuccessToast)
            }
        }
    }
    
    private func handleQRCode(_ code: String) {
        let lowercaseCode = code.lowercased()
        
        if lowercaseCode.contains("bathroom_mirror") ||
           lowercaseCode.contains("tandbørstning_spejl") ||
           lowercaseCode.contains("tandbørstning") ||
           lowercaseCode.contains("toothbrush") {
            // Valid QR code - dismiss delivered notifications and show success toast
            viewModel.completeAllActiveReminders()
            showToast("Godt gået! Tandbørstning registreret.")
            print("✅ Valid toothbrush QR code scanned: \(code)")
        } else {
            // Invalid QR code
            showToast("Ugyldig QR-kode. Prøv igen.")
            print("❌ Invalid QR code: \(code)")
        }
    }
    
    private func showToast(_ message: String) {
        successMessage = message
        withAnimation {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showSuccessToast = false
            }
        }
    }
}

struct ToothbrushReminderCard: View {
    let reminder: ToothbrushReminder
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteDialog = false
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.name)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Text(reminder.timeString)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { onToggle($0) }
            ))
            .labelsHidden()
            
            Button(action: { showDeleteDialog = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color(red: 0.22, green: 0, blue: 0.7).opacity(0.8))
        .cornerRadius(16)
        .alert("Slet påmindelse", isPresented: $showDeleteDialog) {
            Button("Slet", role: .destructive, action: onDelete)
            Button("Annullér", role: .cancel) {}
        } message: {
            Text("Er du sikker på, at du vil slette denne påmindelse?")
        }
    }
}

struct NoRemindersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Ingen tandbørstningspåmindelser")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.8))
            
            Text("Tryk på + for at tilføje en påmindelse")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(32)
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

struct AddToothbrushReminderView: View {
    let onAdd: (Int, Int) -> Void
    let onCancel: () -> Void
    
    @State private var selectedHour = 8
    @State private var selectedMinute = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.22, green: 0, blue: 0.7)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Vælg tidspunkt for påmindelsen")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Hour picker
                        Picker("Time", selection: $selectedHour) {
                            ForEach(0..<24) { hour in
                                Text(String(format: "%02d", hour))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                        
                        Text(":")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Minute picker
                        Picker("Minut", selection: $selectedMinute) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { minute in
                                Text(String(format: "%02d", minute))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 80)
                        .clipped()
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Annullér")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        Button(action: { onAdd(selectedHour, selectedMinute) }) {
                            Text("Tilføj")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.38, green: 0, blue: 0.93))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}

// QR Scanner View
struct QRScannerView: View {
    let onScan: (String) -> Void
    let onCancel: () -> Void
    
    @StateObject private var scanner = QRScannerViewModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            QRScannerRepresentable(scanner: scanner, onScan: onScan)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Scan QR-koden på dit badeværelsesspejl")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .shadow(radius: 4)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// QR Scanner ViewModel
class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    
    var captureSession: AVCaptureSession?
    private var onScanCallback: ((String) -> Void)?
    
    func setupScanner(onScan: @escaping (String) -> Void) {
        self.onScanCallback = onScan
        
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        self.captureSession = session
        
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            scannedCode = stringValue
            onScanCallback?(stringValue)
            
            captureSession?.stopRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
}

// UIViewRepresentable for QR Scanner
struct QRScannerRepresentable: UIViewRepresentable {
    @ObservedObject var scanner: QRScannerViewModel
    let onScan: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        scanner.setupScanner(onScan: onScan)
        
        if let captureSession = scanner.captureSession {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = UIScreen.main.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // Clean up
    }
}

// Toast View - shows a message at the bottom of the screen (like Android Snackbar)
struct ToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.25))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
}

// Extension to get shared ModelContainer
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([
            Medicine.self,
            Reminder.self,
            ToothbrushReminder.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}