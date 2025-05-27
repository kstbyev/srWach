import Foundation

struct SecureMessage: Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let isEncrypted: Bool
    var tokenizedContent: String?
    
    // File message properties
    var primaryPartURLString: String?
    var secondaryPackageURLString: String?
    var decryptedFileURL: URL?
    var transferID: String?
}
