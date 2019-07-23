import WatchKit
import Foundation
import HealthKit
import CoreMotion
import WatchConnectivity

class SleepInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate,URLSessionDelegate{
    
    let healthStore = HKHealthStore()
    var workoutSession : HKWorkoutSession?
    var activeDataQueries = [HKQuery]()
    var workoutStartDate : Date?
    var workoutEndDate : Date?
    var workoutEvents = [HKWorkoutEvent]()
    var metadata = [String: AnyObject]()
    var timer : Timer?
    var isPaused = false
    var counter = 0
    let threshold = 1000
    
    let motionManager = CMMotionManager()
    var allValues = "";
    let defaults = UserDefaults.standard
    var accelerometerOutput = NSMutableArray()
    var accelerometerOutputPost = NSMutableArray()
    
    var watchSession: WCSession? {
        didSet {
            if let session = watchSession {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        watchSession = WCSession.default
        
        if let workoutConfiguration = context as? HKWorkoutConfiguration {
            do {
                
                workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
                workoutSession?.delegate = self
                workoutStartDate = Date()
                healthStore.start(workoutSession!)
                
            } catch {
            }
        }
    }
    
    @IBAction func stopRecording() {
        workoutEndDate = Date()
        healthStore.end(workoutSession!)
    }
    
    func pushToPhone(){
        if WCSession.isSupported() {
            
            let session = WCSession.default
            print("Attempting to post \(self.accelerometerOutputPost.count) entries to phone...")
            
            session.sendMessage(["key": Double((workoutStartDate?.timeIntervalSince1970)!), "acceleration" : self.accelerometerOutputPost], replyHandler: { (response) -> Void in
                if let response = response["response"] as? String {
                    print(response)
                }
                
            }, errorHandler: { (error) -> Void in
                print(error)
            })
        }
    }
    
    func startAccumulatingData(startDate: Date) {
        
        startMotionCapture();
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate, devicePredicate])
        
        let updateHandler: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { query, samples, deletedObjects, queryAnchor, error in
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
                                          predicate: queryPredicate,
                                          anchor: nil,
                                          limit: HKObjectQueryNoLimit,
                                          resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
        
        activeDataQueries.append(query)
    }
    
    
    func stopAccumulatingData() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }
        
        activeDataQueries.removeAll()
        stopTimer()
    }
    
    func pauseAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = true
        }
    }
    
    func resumeAccumulatingData() {
        DispatchQueue.main.sync {
            isPaused = false
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func startMotionCapture(){
        
        print("Motion capture starting...");
        motionManager.accelerometerUpdateInterval = 1.0/60.0;
        
        print("Set accelerometer update interval...");
        
        if (motionManager.isAccelerometerAvailable) {
            
            print("Creating handler...");
            
            let handler:CMAccelerometerHandler = {(data: CMAccelerometerData?, error: Error?) -> Void in
                
                if(data != nil){
                
                    let output : [Double] = [ Date().timeIntervalSince1970, data!.acceleration.x, data!.acceleration.y, data!.acceleration.z]
                    
                    // Mutated
                    self.accelerometerOutput.add(output)
                    self.counter = self.counter + 1;
                    
                    // Size checked
                    if(self.threshold <= self.counter){
                        
                        print("Time to post...");
                        self.counter = 0;
                        self.accelerometerOutputPost = self.accelerometerOutput.mutableCopy() as! NSMutableArray
                        self.accelerometerOutput = NSMutableArray()
                        
                        self.pushToPhone()
                    }
                }
            }
            
            print("Sending accelerometer updates to queue...");
            
            motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
            
        }
        else {
            print("No accelerometer available.")
        }
    }
    
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session did fail with error: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        workoutEvents.append(event)
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        switch toState {
        case .running:
            if fromState == .notStarted {
                startAccumulatingData(startDate: workoutStartDate!)
            } else {
                resumeAccumulatingData()
            }
            
        case .paused:
            pauseAccumulatingData()
            
        case .ended:
            stopAccumulatingData()
            saveWorkout()
        default:
            break
        }
        
    }
    
    private func saveWorkout() {
        
        let configuration = workoutSession!.workoutConfiguration
        
        let workout = HKWorkout(activityType: configuration.activityType, start: workoutStartDate!, end: workoutEndDate!)
        
        // Pass the workout to Summary Interface Controller
        WKInterfaceController.reloadRootControllers(withNames: ["CompletionInterfaceController"], contexts: [workout])
    }
}




extension SleepInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation for HR completed")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        print("Received application context: ", applicationContext)
    }
}

