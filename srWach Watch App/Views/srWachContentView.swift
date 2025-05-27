import SwiftUI

struct srWachContentView: View {
    @StateObject private var viewModel = srWachWatchViewModel()
    @State private var messageText = ""
    @State private var showingCompose = false
    @State private var showingAuth = false
    
    var body: some View {
        if !viewModel.isAuthenticated {
            AuthenticationView(viewModel: viewModel)
        } else {
            TabView {
                // Messages Tab
                List {
                    ForEach(viewModel.messages) { message in
                        MessageRow(message: message)
                    }
                }
                .listStyle(.carousel)
                
                // Compose Tab
                VStack {
                    if showingCompose {
                        TextField("Message", text: $messageText)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        
                        Button("Send") {
                            Task {
                                if await viewModel.sendMessage(messageText) {
                                    messageText = ""
                                    showingCompose = false
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: { showingCompose = true }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                        }
                    }
                }
                
                // Settings Tab
                List {
                    Section("Security") {
                        Toggle("Encryption", isOn: $viewModel.isEncryptionEnabled)
                        
                        Picker("Security Level", selection: $viewModel.securityLevel) {
                            ForEach(SecurityLevel.allCases) { level in
                                HStack {
                                    Image(systemName: level.iconName)
                                        .foregroundColor(level.color)
                                    Text(level.description)
                                }
                                .tag(level)
                            }
                        }
                        
                        Button("Lock App") {
                            viewModel.isAuthenticated = false
                        }
                        .foregroundColor(.red)
                    }
                    
                    Section("Status") {
                        HStack {
                            Text("Connection")
                            Spacer()
                            Image(systemName: viewModel.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(viewModel.isConnected ? .green : .red)
                        }
                        
                        HStack {
                            Text("Watch Authentication")
                            Spacer()
                            Image(systemName: viewModel.biometricType == .watchAuth ? "lock.shield.fill" : "lock.slash")
                                .foregroundColor(viewModel.biometricType == .watchAuth ? .blue : .gray)
                        }
                    }
                }
                .listStyle(.carousel)
            }
            .tabViewStyle(.page)
        }
    }
}

struct AuthenticationView: View {
    @ObservedObject var viewModel: srWachWatchViewModel
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("SafeRelay")
                .font(.title2)
                .bold()
            
            Text("Secure Messaging")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                isAuthenticating = true
                Task {
                    _ = await viewModel.authenticate()
                    isAuthenticating = false
                }
            }) {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Authenticate")
                        .bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
        }
    }
}

struct MessageRow: View {
    let message: SecureMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if message.isEncrypted {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if let tokenized = message.tokenizedContent {
                Text(tokenized)
                    .font(.caption)
            } else {
                Text(message.content)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
} 