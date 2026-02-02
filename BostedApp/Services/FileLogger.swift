import Foundation

class FileLogger {
    static let shared = FileLogger()
    
    private let logFileName = "BostedApp.log"
    private var logFileURL: URL?
    private let maxLogSize: Int = 5 * 1024 * 1024 // 5 MB
    
    private init() {
        setupLogFile()
    }
    
    private func setupLogFile() {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not find documents directory")
            return
        }
        
        logFileURL = documentsDirectory.appendingPathComponent(logFileName)
        
        // Create file if it doesn't exist
        if let url = logFileURL, !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
            log("📝 Log file created at: \(url.path)")
        }
    }
    
    func log(_ message: String, level: LogLevel = .info) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.emoji)] \(message)\n"
        
        // Also print to console (if connected to Xcode)
        print(logMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        
        // Write to file
        guard let url = logFileURL else { return }
        
        // Check file size and rotate if needed
        checkAndRotateLogIfNeeded()
        
        // Append to file
        if let data = logMessage.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    
    private func checkAndRotateLogIfNeeded() {
        guard let url = logFileURL else { return }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int, fileSize > maxLogSize {
                // Rotate log file
                let backupURL = url.deletingPathExtension().appendingPathExtension("old.log")
                try? FileManager.default.removeItem(at: backupURL)
                try? FileManager.default.moveItem(at: url, to: backupURL)
                FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
                log("🔄 Log file rotated")
            }
        } catch {
            print("Error checking log file size: \(error)")
        }
    }
    
    func getLogContent() -> String {
        guard let url = logFileURL else { return "No log file found" }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            return "Error reading log file: \(error.localizedDescription)"
        }
    }
    
    func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    func clearLog() {
        guard let url = logFileURL else { return }
        
        try? FileManager.default.removeItem(at: url)
        FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        log("🗑️ Log cleared")
    }
    
    func shareLog() -> URL? {
        return logFileURL
    }
}

enum LogLevel {
    case debug
    case info
    case warning
    case error
    case success
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .success: return "✅"
        }
    }
}

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Copenhagen")
        return formatter
    }()
}