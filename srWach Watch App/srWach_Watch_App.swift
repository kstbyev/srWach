import SwiftUI

@main
struct srWach_Watch_App: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashView(isActive: $showSplash)
            } else {
                SecureTransferView()
            }
        }
    }
} 