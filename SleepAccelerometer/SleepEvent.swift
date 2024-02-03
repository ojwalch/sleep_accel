
import UIKit
import CoreData

class SleepEvent: NSObject {
  
  class func getAllEvents() async throws -> [Double] {
    guard let appDelegate = await UIApplication.shared.delegate as? AppDelegate else {
      return []
    }
    
    let managedContext = await appDelegate.persistentContainer.viewContext
    
    let fetchRequest: NSFetchRequest<NSDictionary> = NSFetchRequest(entityName: "Acceleration")
    fetchRequest.resultType = .dictionaryResultType
    fetchRequest.propertiesToFetch = ["start_time"]
    fetchRequest.returnsDistinctResults = true
    
    let result = try await managedContext.perform {
      return try managedContext.fetch(fetchRequest)
    }
    let startTimes = result.compactMap { dict -> Double? in
      return dict["start_time"] as? Double
    }
    return startTimes
  }
  
  // Get all acceleration data types for start time
  class func getAccelerationFor(startTime: Double) async throws -> [[Double]] {
    guard let appDelegate = await UIApplication.shared.delegate as? AppDelegate else {
      return []
    }
    
    let managedContext = await appDelegate.persistentContainer.viewContext
    
    let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Acceleration")
    fetchRequest.predicate = NSPredicate(format: "start_time == %@", String(startTime))
    
    let result = try await managedContext.perform {
      return try fetchRequest.execute()
    }
    
    let values: [[Double]] = result.compactMap { data in
      guard let timeStamp = data.value(forKey: "time_stamp") as? Double,
            let xAccel = data.value(forKey: "x_accel") as? Double,
            let yAccel = data.value(forKey: "y_accel") as? Double,
            let zAccel = data.value(forKey: "z_accel") as? Double else {
        return nil
      }
      return [timeStamp, xAccel, yAccel, zAccel]
    }
    return values
  }
  
  class func deleteAccelerationFor(startTime: Double) async throws -> Int {
    guard let appDelegate = await UIApplication.shared.delegate as? AppDelegate else {
      return 0
    }
    
    let context = await appDelegate.persistentContainer.newBackgroundContext()
    return try await context.perform {
      let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Acceleration")
      request.predicate = NSPredicate(format: "start_time == %@", String(startTime))
      let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
      batchDeleteRequest.resultType = .resultTypeCount
      let result = try context.execute(batchDeleteRequest) as! NSBatchDeleteResult
      print("Deleted this many results: " + String(result.result as! Int))
      return result.result as! Int
    }
  }
  
  class func writeEvent(start : Double, timeStamp : Double, x : Double, y : Double, z : Double){
    DispatchQueue.main.async{
      guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        return
      }
      
      let managedContext = appDelegate.persistentContainer.viewContext
      let entity = NSEntityDescription.entity(forEntityName: "Acceleration", in: managedContext)
      
      if(entity != nil){
        
        let accelItem = NSManagedObject(entity: entity!, insertInto: managedContext)
        accelItem.setValue(x, forKeyPath: "x_accel")
        accelItem.setValue(y, forKeyPath: "y_accel")
        accelItem.setValue(z, forKeyPath: "z_accel")
        accelItem.setValue(timeStamp, forKeyPath: "time_stamp")
        accelItem.setValue(round(start), forKeyPath: "start_time")
        
        do {
          try managedContext.save()
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
      }
    }
  }
}

