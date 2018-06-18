import WatchKit
import Foundation
import HealthKit
import WatchConnectivity

class ConfigurationInterfaceController: WKInterfaceController {
    
    var watchSession: WCSession? {
        didSet {
            if let session = watchSession {
                print("Creating watch session")
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        watchSession = WCSession.default
        setTitle("Sleep Tracker")
    }

    override func didAppear() {
        super.didAppear()
    }

    @IBAction func beginRecording() {
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .yoga
        workoutConfiguration.locationType = .indoor
        
        
        if #available(watchOSApplicationExtension 4.0, *) {
            WKInterfaceController.reloadRootPageControllers(withNames: ["SleepInterfaceController"], contexts: [workoutConfiguration], orientation: WKPageOrientation.vertical, pageIndex: 0)
        } else {
            WKInterfaceController.reloadRootControllers(withNames: ["SleepInterfaceController"], contexts: [workoutConfiguration])
        }
    }
    
}

extension ConfigurationInterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation completed")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        print("Watch received app context: ", applicationContext)
        
        if (applicationContext["ConnectedKey"] as? Bool) == true {
            print("Connected")
        }
    }
}

