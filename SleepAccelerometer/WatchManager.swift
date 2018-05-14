import Foundation
import WatchConnectivity

class WatchManager: NSObject {
    
    fileprivate var watchSession: WCSession?
    
    override init() {
        super.init()
        watchSession = WCSession.default
        watchSession?.delegate = self
        watchSession?.activate()
    }
    
}

extension WatchManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session activation did complete")
    }
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivated")
    }
    
    func session(_: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void){
        
        let key =  message["key"] as! Double
        let accel = message["acceleration"] as! NSArray
        
        for i in 0..<accel.count {
            
            let item = accel[i] as! [Double]
            SleepEvent.writeEvent(start : key, timeStamp : item[0], x : item[1], y : item[2], z : item[3])
            
        }
        
        let response = "Data written to file: \(accel.count)"
        // Reply
        replyHandler(["response": response])
        
        
    }
    
    
}

