import SwiftUI
import WatchKit
import WatchConnectivity

struct SecureTransferView: View {
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var transferManager: TransferManager
    @StateObject private var contextManager = ContextManager()
    @State private var selectedFile: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSelectingFile = false
    @State private var isRedactionPreview = false
    @State private var redactedText: String = ""
    @State private var foundPII: [String] = []
    @State private var isExporting = false
    @State private var exportedString: String = ""
    @State private var isImporting = false
    @State private var importString: String = ""
    @State private var showImportError = false
    @State private var selectedChannels: [ChannelManager.ChannelType] = [.watchConnectivity]
    @State private var showCopiedAlert = false
    
    init() {
        let securityManager = SecurityManager()
        _transferManager = StateObject(wrappedValue: TransferManager(securityManager: securityManager))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Title
                Text("SafeRelay+")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                // Security status
                SecurityStatusView(isSecure: contextManager.isSafeContext, description: contextManager.contextDescription)
                    .padding(.vertical, 5)
                
                // Main buttons
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation { isSelectingFile = true }
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 16))
                            Text("Choose File")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(WatchButtonStyle())
                    
                    if let fileData = selectedFile, let fileString = String(data: fileData, encoding: .utf8) {
                        // Redaction preview
                        if foundPII.count > 0 {
                            Button(action: { isRedactionPreview = true }) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text("Preview Redacted")
                                }
                            }
                        }
                        // Export/Import
                        HStack(spacing: 8) {
                            Button(action: exportFile) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                            .buttonStyle(WatchButtonStyle())
                            Button(action: { isImporting = true }) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Import")
                            }
                            .buttonStyle(WatchButtonStyle())
                        }
                        // Channel selection
                        VStack(spacing: 4) {
                            Text("Channels:")
                                .font(.system(size: 14, weight: .medium))
                            HStack(spacing: 8) {
                                ChannelToggle(channel: .watchConnectivity, selected: $selectedChannels)
                                ChannelToggle(channel: .cloudKit, selected: $selectedChannels)
                                ChannelToggle(channel: .bluetooth, selected: $selectedChannels)
                            }
                        }
                        // Send button
                        Button(action: sendFile) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                                Text("Send")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(WatchButtonStyle())
                        .disabled(transferManager.isTransferring || !contextManager.isSafeContext)
                    }
                }
                
                // Transfer progress
                if transferManager.isTransferring {
                    VStack(spacing: 8) {
                        ProgressView(value: transferManager.transferProgress)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        Text("\(Int(transferManager.transferProgress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 10)
                }
                // Error messages
                if let error = transferManager.lastError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .alert("Notification", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Copied!", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
        .sheet(isPresented: $isSelectingFile) {
            FilePickerView(selectedData: $selectedFile, onPIIFound: handlePII)
        }
        .sheet(isPresented: $isRedactionPreview) {
            VStack(spacing: 10) {
                Text("Redacted Preview")
                    .font(.headline)
                ScrollView {
                    Text(redactedText)
                        .font(.system(size: 13, design: .monospaced))
                        .padding()
                }
                Text("Found PII: \(foundPII.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.orange)
                HStack {
                    Button("Send Redacted") {
                        if let data = redactedText.data(using: .utf8) {
                            selectedFile = data
                        }
                        isRedactionPreview = false
                    }
                    .buttonStyle(WatchButtonStyle())
                    Button("Send As Is") {
                        isRedactionPreview = false
                    }
                    .buttonStyle(WatchButtonStyle())
                }
            }
            .padding()
        }
        .sheet(isPresented: $isExporting) {
            VStack(spacing: 10) {
                Text("Exported String (Base64)")
                    .font(.headline)
                ScrollView {
                    Text(exportedString)
                        .font(.system(size: 11, design: .monospaced))
                        .padding()
                }
                Button("Done") {
                    showCopiedAlert = true
                    isExporting = false
                }
                .buttonStyle(WatchButtonStyle())
                Button("Close") {
                    isExporting = false
                }
                .buttonStyle(WatchButtonStyle())
            }
            .padding()
        }
        .sheet(isPresented: $isImporting) {
            VStack(spacing: 10) {
                Text("Import String (Base64)")
                    .font(.headline)
                TextField("Paste here", text: $importString)
                    .padding()
                Button("Import") {
                    if let data = CrossPlatformManager.shared.importData(importString) {
                        selectedFile = data
                        isImporting = false
                    } else {
                        showImportError = true
                    }
                }
                .buttonStyle(WatchButtonStyle())
                Button("Close") {
                    isImporting = false
                }
                .buttonStyle(WatchButtonStyle())
            }
            .padding()
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Invalid Base64 string")
            }
        }
    }
    
    private func sendFile() {
        guard let fileData = selectedFile else { return }
        // Multi-channel fragmented transfer
        let fragments = securityManager.splitData(fileData, into: selectedChannels.count)
        for (i, fragment) in fragments.enumerated() {
            let channel = selectedChannels.indices.contains(i) ? selectedChannels[i] : .watchConnectivity
            ChannelManager.shared.sendFragment(fragment, channel: channel) { success in
                // Можно добавить обработку статуса отправки по каждому каналу
            }
        }
        alertMessage = "File fragments sent via: " + selectedChannels.map { $0.displayName }.joined(separator: ", ")
        showingAlert = true
    }
    
    private func handlePII(_ fileData: Data?) {
        guard let fileData = fileData, let fileString = String(data: fileData, encoding: .utf8) else { return }
        let (redacted, found) = RedactionManager.shared.redactPII(in: fileString)
        redactedText = redacted
        foundPII = found
    }
    
    private func exportFile() {
        guard let fileData = selectedFile else { return }
        exportedString = CrossPlatformManager.shared.exportData(fileData)
        isExporting = true
    }
}

struct WatchButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecurityStatusView: View {
    let isSecure: Bool
    let description: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSecure ? "lock.fill" : "lock.open.fill")
                .foregroundColor(isSecure ? .green : .red)
            Text(isSecure ? "Secured" : "Untrusted")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSecure ? .green : .red)
            Text(description)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}

struct ChannelToggle: View {
    let channel: ChannelManager.ChannelType
    @Binding var selected: [ChannelManager.ChannelType]
    var body: some View {
        Button(action: {
            if selected.contains(channel) {
                selected.removeAll { $0 == channel }
            } else {
                selected.append(channel)
            }
        }) {
            HStack {
                Image(systemName: channel.iconName)
                    .foregroundColor(selected.contains(channel) ? .blue : .gray)
                Text(channel.displayName)
                    .font(.system(size: 12))
                    .foregroundColor(selected.contains(channel) ? .blue : .gray)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selected.contains(channel) ? Color.blue.opacity(0.15) : Color.gray.opacity(0.08))
            )
        }
    }
}

extension ChannelManager.ChannelType {
    var displayName: String {
        switch self {
        case .watchConnectivity: return "WatchConn"
        case .cloudKit: return "CloudKit"
        case .bluetooth: return "Bluetooth"
        }
    }
    var iconName: String {
        switch self {
        case .watchConnectivity: return "applewatch"
        case .cloudKit: return "icloud"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        }
    }
}

struct FilePickerView: View {
    @Binding var selectedData: Data?
    var onPIIFound: ((Data?) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("File Type")) {
                Button(action: { selectTextFile() }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("Text File")
                            .font(.system(size: 16))
                    }
                }
                Button(action: { selectJSONFile() }) {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundColor(.blue)
                        Text("JSON File")
                            .font(.system(size: 16))
                    }
                }
            }
            Section {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Cancel")
                            .font(.system(size: 16))
                    }
                }
            }
        }
    }
    private func selectTextFile() {
        let text = "This is a test file for SafeRelay+. Email: test@example.com, Phone: +12345678901, Name: John"
        let data = text.data(using: .utf8)
        selectedData = data
        onPIIFound?(data)
        dismiss()
    }
    private func selectJSONFile() {
        let json: [String: Any] = [
            "name": "John",
            "type": "JSON",
            "email": "test@example.com",
            "phone": "+12345678901",
            "timestamp": Date().timeIntervalSince1970
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: json), let data = String(data: jsonData, encoding: .utf8)?.data(using: .utf8) {
            selectedData = data
            onPIIFound?(data)
        }
        dismiss()
    }
}

#Preview {
    SecureTransferView()
} 