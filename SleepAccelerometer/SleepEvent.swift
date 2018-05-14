
import UIKit
import CoreData

class SleepEvent: NSObject {
    
    var values : [NSManagedObject] = []
    
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
        
        if(result.count > 0 ){
            return result[0].allValues as! [Double]
        }

        return []
    }
    
    
    
    func readAccelerationFor(startTime : Double){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Acceleration")
        fetchRequest.predicate = NSPredicate(format: "start_time == %@", String(startTime))
        
        do {
            values = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        
        /*
         let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Acceleration")
         fetchRequest.propertiesToFetch = ["start_time"]
         fetchRequest.returnsDistinctResults = true
         
         do {
         let result = try managedContext.fetch(fetchRequest)
         for data in result as! [NSManagedObject] {
         //       print(data.value(forKey: "start_time"))
         
         }
         } catch {
         
         print("Failed")
         }
         
         */

        
    }
    
    func appendData(){
        
    }
    
    class func writeEvent(start : Double, timeStamp : Double, x : Double, y : Double, z : Double){
        
        DispatchQueue.main.async{
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            let names = appDelegate.persistentContainer.managedObjectModel.entities.map({ (entity) -> String in
                print()
                return entity.name!
            })
            let entity = NSEntityDescription.entity(forEntityName: "Acceleration", in: managedContext)

            if(entity != nil){
            
            let accelItem = NSManagedObject(entity: entity!, insertInto: managedContext)
            accelItem.setValue(x, forKeyPath: "x_accel")
            accelItem.setValue(y, forKeyPath: "y_accel")
            accelItem.setValue(z, forKeyPath: "z_accel")
            accelItem.setValue(timeStamp, forKeyPath: "time_stamp")
            accelItem.setValue(start, forKeyPath: "start_time")
            
            do {
                try managedContext.save()
                
            } catch let error as NSError {
                
                print("Could not save. \(error), \(error.userInfo)")
            }
            }
        }
        
    }
    
    func readEvent(){
        
    }
    
}

