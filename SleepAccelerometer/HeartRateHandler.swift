import Foundation
import UIKit

class HeartRateHandler: NSObject {
    var stringHolder = [String]()
    
    let health: HKHealthStore = HKHealthStore()
    let heartRateUnit:HKUnit = HKUnit(from: "count/min")
    let heartRateType:HKQuantityType   = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
    var heartRateQuery:HKSampleQuery?
    
    // Retrieve heart rate data and save to file 
    func retrieveHeartRate(start: Date, end: Date, path: URL) {
        
        if let sleepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        {
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 3000000, sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
                
                if error != nil {
                    
                    print("Unable to query")
                    return
                    
                }
                
                if let result = tmpResult {
                    
                    for item in result {
                        if let sample = item as? HKQuantitySample {
                            let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                            self.stringHolder.append("\(sample.startDate.timeIntervalSince1970),\(value)")
                        }
                    }
                }
                
                // Write string to path
                self.writeString(path: path)
            }
            
            health.execute(query)
        }
    }
    
    
    func writeString(path: URL){
        let file = "hr.csv"
        let text = self.stringHolder.joined(separator: "\n")
        
        do {
            try text.write(to: path, atomically: false, encoding: String.Encoding.utf8)
            print("Save path: " + path.absoluteString)
            
        }
        catch {
            print("Could not write HR to file");
        }
    }
  
}
