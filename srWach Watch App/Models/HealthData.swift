import Foundation
import HealthKit

struct HealthData: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let heartRate: Double
    let steps: Int
    let sleepHours: Double
    let stressLevel: Int // 1-10 scale
    let activityMinutes: Int
    
    init(id: UUID = UUID(), timestamp: Date = Date(), heartRate: Double, steps: Int, sleepHours: Double, stressLevel: Int, activityMinutes: Int) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.steps = steps
        self.sleepHours = sleepHours
        self.stressLevel = stressLevel
        self.activityMinutes = activityMinutes
    }
}

// Health Data Manager to handle HealthKit interactions
class HealthDataManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var latestHeartRate: Double = 0
    @Published var dailySteps: Int = 0
    @Published var sleepHours: Double = 0
    @Published var stressLevel: Int = 5
    
    func requestAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.startHeartRateQuery()
                self.fetchDailySteps()
                self.fetchSleepData()
            }
        }
    }
    
    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { query, samples, deletedObjects, anchor, error in
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            DispatchQueue.main.async {
                if let lastSample = samples.last {
                    self.latestHeartRate = lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDailySteps() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            DispatchQueue.main.async {
                self.dailySteps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample] else { return }
            
            let totalSleepTime = samples.reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            DispatchQueue.main.async {
                self.sleepHours = totalSleepTime / 3600 // Convert to hours
            }
        }
        
        healthStore.execute(query)
    }
    
    func updateStressLevel(_ level: Int) {
        self.stressLevel = max(1, min(10, level))
    }
} 