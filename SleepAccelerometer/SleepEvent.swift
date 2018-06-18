
import UIKit
import CoreData

class SleepEvent: NSObject {
    
    // Get all saved sleep event start times
    class func getAllEvents() -> [Double]{
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Acceleration")
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.propertiesToFetch = ["start_time"]
        fetchRequest.returnsDistinctResults = true
        let result = try! managedContext.fetch(fetchRequest as! NSFetchRequest<NSFetchRequestResult>) as! [NSDictionary]
        print(result)
        
        var startTimes : [Double] = []
        for dict in result{
            startTimes.append(dict.value(forKey: "start_time")! as! Double)
        }
        
        return startTimes
    }
    
    
    // Get all acceleration data types for start time
    class func getAccelerationFor(startTime : Double) -> [[Double]]{
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Acceleration")
        fetchRequest.predicate = NSPredicate(format: "start_time == %@", String(startTime))
        var values : [[Double]] = []
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result {
                
                let arr : [Double] = [data.value(forKey: "time_stamp") as! Double,data.value(forKey: "x_accel") as! Double,data.value(forKey: "y_accel") as! Double,data.value(forKey: "z_accel") as! Double]
                
                values.append(arr)
                
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return values
        
    }
    
    // Delete saved acceleration data
    class func deleteAccelerationFor(startTime : Double){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Acceleration")
        fetchRequest.predicate = NSPredicate(format: "start_time == %@", String(startTime))

        do {
            let result = try managedContext.fetch(fetchRequest)
            for object in result {
                
                managedContext.delete(object)
                
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        do {
            try managedContext.save()
        } catch {

        }

    }
    
    class func writeEvent(start : Double, timeStamp : Double, x : Double, y : Double, z : Double){
        
        DispatchQueue.main.async{
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            /* For debugging: let names = appDelegate.persistentContainer.managedObjectModel.entities.map({ (entity) -> String in
                print()
                return entity.name!
            })*/
            
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

