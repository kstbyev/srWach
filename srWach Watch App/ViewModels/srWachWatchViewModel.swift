import SwiftUI
import WatchConnectivity
import LocalAuthentication

class srWachWatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var messages: [SecureMessage] = []
    @Published var isConnected = false
    @Published var securityLevel: SecurityLevel = .standard
    @Published var isEncryptionEnabled = true
    @Published var isAuthenticated = false
    @Published var biometricType: BiometricType = .none
    
    enum BiometricType {
        case none, watchAuth
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        checkBiometricType()
    }
    
    private func checkBiometricType() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            biometricType = .watchAuth
        } else {
            biometricType = .none
        }
    }
    
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                 localizedReason: "Authenticate to access messages") { success, error in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let content = message["content"] as? String {
                let newMessage = SecureMessage(
                    id: UUID(),
                    content: content,
                    timestamp: Date(),
                    isEncrypted: message["isEncrypted"] as? Bool ?? false,
                    tokenizedContent: message["tokenizedContent"] as? String
                )
                self.messages.append(newMessage)
            }
        }
    }
    
    func sendMessage(_ text: String) async -> Bool {
        guard WCSession.default.activationState == .activated else { return false }
        guard isAuthenticated else { return false }
        
        let message: [String: Any] = [
            "content": text,
            "isEncrypted": isEncryptionEnabled,
            "timestamp": Date(),
            "securityLevel": securityLevel.rawValue
        ]
        
        return await withCheckedContinuation { continuation in
            WCSession.default.sendMessage(message, replyHandler: { _ in
                continuation.resume(returning: true)
            }, errorHandler: { _ in
                continuation.resume(returning: false)
            })
        }
    }
    
    func toggleEncryption() {
        isEncryptionEnabled.toggle()
    }
} 