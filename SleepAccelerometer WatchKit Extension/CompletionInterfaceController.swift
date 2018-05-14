

import WatchKit
import Foundation
import HealthKit

class CompletionInterfaceController: WKInterfaceController {
    
    var workout: HKWorkout?
    
    @IBOutlet var durationLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        workout = context as? HKWorkout
        
        setTitle("Recording complete.")
    }
    
    override func willActivate() {
        super.willActivate()
        
        guard let workout = workout else {
            return
        }
        
        let duration = workout.endDate.timeIntervalSince(workout.startDate)
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.unitsStyle = .positional
        durationFormatter.allowedUnits = [.second, .minute, .hour]
        durationFormatter.zeroFormattingBehavior = .pad
        
        if let string = durationFormatter.string(from: duration) {
            durationLabel.setText(string)
        } else {
        }

    }
    
    @IBAction func doneTapped() {
        if #available(watchOSApplicationExtension 4.0, *) {
            WKInterfaceController.reloadRootPageControllers(withNames: ["ConfigurationInterfaceController"], contexts: nil, orientation: WKPageOrientation.vertical, pageIndex: 0)
        } else {
            WKInterfaceController.reloadRootControllers(withNames: ["ConfigurationInterfaceController"], contexts: nil)
        }
    }
}
