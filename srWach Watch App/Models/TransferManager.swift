import Foundation
import WatchConnectivity

class TransferManager: NSObject, ObservableObject {
    @Published var isTransferring = false
    @Published var transferProgress: Double = 0
    @Published var lastError: String?
    @Published var receivedParts: [Int: Data] = [:]
    
    private var session: WCSession?
    private var securityManager: SecurityManager
    private var expectedParts: Int = 0
    
    init(securityManager: SecurityManager) {
        self.securityManager = securityManager
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func sendSecureData(_ data: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        isTransferring = true
        transferProgress = 0
        
        do {
            // ncrypting the data
            let encryptedData = try securityManager.encryptData(data)
            
            // Splitting into parts
            let parts = securityManager.splitData(encryptedData, into: 3)
            expectedParts = parts.count
            
            // Sending each part
            for (index, part) in parts.enumerated() {
                let message = [
                    "part": index,
                    "totalParts": parts.count,
                    "data": part
                ] as [String : Any]
                
                session?.transferUserInfo(message)
                transferProgress = Double(index + 1) / Double(parts.count)
            }
            
            completion(.success(()))
        } catch {
            lastError = error.localizedDescription
            completion(.failure(error))
        }
        
        isTransferring = false
    }
    
    func receiveSecureData(_ data: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let decryptedData = try securityManager.decryptData(data)
            completion(.success(decryptedData))
        } catch {
            lastError = error.localizedDescription
            completion(.failure(error))
        }
    }
    
    private func checkAndCombineParts() {
        guard receivedParts.count == expectedParts else { return }
        
        // Сортируем части по индексу
        let sortedParts = receivedParts.sorted { $0.key < $1.key }.map { $0.value }
        
        // Объединяем части
        let combinedData = securityManager.combineData(sortedParts)
        
        // Расшифровываем данные
        do {
            let decryptedData = try securityManager.decryptData(combinedData)
            // Здесь можно добавить обработку расшифрованных данных
            print("Данные успешно расшифрованы")
        } catch {
            lastError = error.localizedDescription
        }
        
        // Очищаем буфер
        receivedParts.removeAll()
    }
}

// MARK: - WCSessionDelegate
extension TransferManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            lastError = error.localizedDescription
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        guard let part = userInfo["part"] as? Int,
              let totalParts = userInfo["totalParts"] as? Int,
              let data = userInfo["data"] as? Data else {
            return
        }
        
        expectedParts = totalParts
        receivedParts[part] = data
        
        // Проверяем, все ли части получены
        checkAndCombineParts()
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
} 
