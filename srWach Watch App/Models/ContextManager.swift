import Foundation
import CoreLocation
import Network
import WatchKit

class ContextManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isSafeContext: Bool = true
    @Published var contextDescription: String = ""
    private let locationManager = CLLocationManager()
    private let monitor = NWPathMonitor()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.evaluateContext()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        evaluateContext()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        evaluateContext()
    }
    
    func evaluateContext() {
        // Example: if the network is not secured or the charge is low, it is unsafe
        let batteryLevel = WKInterfaceDevice.current().batteryLevel
        let hour = Calendar.current.component(.hour, from: Date())
        let isNight = hour < 7 || hour > 22
        let isLowBattery = batteryLevel >= 0 && batteryLevel < 0.2
        let isWifi = monitor.currentPath.usesInterfaceType(.wifi)
        let isCellular = monitor.currentPath.usesInterfaceType(.cellular)
        
        if isLowBattery || isCellular || isNight {
            isSafeContext = false
            contextDescription = "Untrusted environment: " +
                (isLowBattery ? "Low battery. " : "") +
                (isCellular ? "Cellular network. " : "") +
                (isNight ? "Night time." : "")
        } else {
            isSafeContext = true
            contextDescription = "Trusted environment: Wi-Fi, normal battery, daytime."
        }
    }
} 