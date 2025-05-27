import Foundation

class RedactionManager {
    static let shared = RedactionManager()
    
    // Простейший поиск e-mail, телефонов, имён (можно расширить)
    func redactPII(in text: String) -> (redacted: String, found: [String]) {
        var found: [String] = []
        var redacted = text
        // Email
        let emailRegex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        let emailMatches = emailRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in emailMatches.reversed() {
            if let range = Range(match.range, in: text) {
                let email = String(text[range])
                found.append(email)
                redacted.replaceSubrange(range, with: "[REDACTED_EMAIL]")
            }
        }
        // Phone
        let phoneRegex = try! NSRegularExpression(pattern: "\\+?\\d{10,15}")
        let phoneMatches = phoneRegex.matches(in: redacted, range: NSRange(redacted.startIndex..., in: redacted))
        for match in phoneMatches.reversed() {
            if let range = Range(match.range, in: redacted) {
                let phone = String(redacted[range])
                found.append(phone)
                redacted.replaceSubrange(range, with: "[REDACTED_PHONE]")
            }
        }
        // Name (очень базово)
        let nameRegex = try! NSRegularExpression(pattern: "\\b([A-Z][a-z]+)\\b")
        let nameMatches = nameRegex.matches(in: redacted, range: NSRange(redacted.startIndex..., in: redacted))
        for match in nameMatches.reversed() {
            if let range = Range(match.range, in: redacted) {
                let name = String(redacted[range])
                found.append(name)
                redacted.replaceSubrange(range, with: "[REDACTED_NAME]")
            }
        }
        return (redacted, found)
    }
    
    // Для JSON
    func redactPII(in json: [String: Any]) -> (redacted: [String: Any], found: [String]) {
        var found: [String] = []
        var redacted = json
        for (key, value) in json {
            if let str = value as? String {
                let (r, f) = redactPII(in: str)
                redacted[key] = r
                found.append(contentsOf: f)
            }
        }
        return (redacted, found)
    }
} 