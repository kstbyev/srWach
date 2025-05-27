import SwiftUI

struct DashboardView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Heart Rate View
            VStack {
                Text("Heart Rate")
                    .font(.headline)
                Text("\(Int(healthManager.latestHeartRate)) BPM")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.red)
            }
            .tag(0)
            
            // Steps View
            VStack {
                Text("Steps")
                    .font(.headline)
                Text("\(healthManager.dailySteps)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
            }
            .tag(1)
            
            // Sleep View
            VStack {
                Text("Sleep")
                    .font(.headline)
                Text(String(format: "%.1f hrs", healthManager.sleepHours))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
            }
            .tag(2)
            
            // Stress Level View
            VStack {
                Text("Stress Level")
                    .font(.headline)
                Text("\(healthManager.stressLevel)/10")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(stressColor)
                
                HStack {
                    Button("-") {
                        healthManager.updateStressLevel(healthManager.stressLevel - 1)
                    }
                    Button("+") {
                        healthManager.updateStressLevel(healthManager.stressLevel + 1)
                    }
                }
            }
            .tag(3)
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear {
            healthManager.requestAuthorization()
        }
    }
    
    private var stressColor: Color {
        switch healthManager.stressLevel {
        case 1...3: return .green
        case 4...7: return .yellow
        default: return .red
        }
    }
}

#Preview {
    DashboardView()
} 