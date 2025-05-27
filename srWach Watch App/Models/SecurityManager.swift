import Foundation
import CryptoKit
import Security

class SecurityManager: ObservableObject {
    @Published var isEncrypting = false
    @Published var isDecrypting = false
    @Published var lastError: String?
    
    private let keychain = KeychainWrapper.standard
    
    // MARK: - Encryption
    func encryptData(_ data: Data) throws -> Data {
        guard let key = try? generateKey() else {
            throw SecurityError.keyGenerationFailed
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    func decryptData(_ encryptedData: Data) throws -> Data {
        guard let key = try? generateKey() else {
            throw SecurityError.keyGenerationFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    // MARK: - Key Management
    private func generateKey() throws -> SymmetricKey {
        if let existingKey = try? loadKey() {
            return existingKey
        }
        
        let key = SymmetricKey(size: .bits256)
        try saveKey(key)
        return key
    }
    
    private func saveKey(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try keychain.set(keyData, forKey: "encryptionKey")
    }
    
    private func loadKey() throws -> SymmetricKey {
        guard let keyData = try? keychain.data(forKey: "encryptionKey") else {
            throw SecurityError.keyNotFound
        }
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Data Splitting
    func splitData(_ data: Data, into parts: Int) -> [Data] {
        let chunkSize = (data.count + parts - 1) / parts
        return stride(from: 0, to: data.count, by: chunkSize).map {
            let end = min($0 + chunkSize, data.count)
            return data[$0..<end]
        }
    }
    
    func combineData(_ parts: [Data]) -> Data {
        return parts.reduce(Data(), +)
    }
}

// MARK: - Errors
enum SecurityError: Error {
    case keyGenerationFailed
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
}

// MARK: - KeychainWrapper
class KeychainWrapper {
    static let standard = KeychainWrapper()
    
    func set(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keyGenerationFailed
        }
    }
    
    func data(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw SecurityError.keyNotFound
        }
        
        return data
    }
} 