
import UIKit
import CoreData

class MainTableViewController: UITableViewController {

    var savedEvents : [Double] = []
    var watchManager : WatchManager?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        let healthHelper = HealthHelper()
        healthHelper.getHealthPermissions()

        savedEvents = SleepEvent.getAllEvents()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(savedEvents.count > 0){
            return savedEvents.count
        }
        
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath)

        if(savedEvents.count > 0){
            let date = Date(timeIntervalSince1970: savedEvents[indexPath.row])
            
            let dayTimePeriodFormatter = DateFormatter()
            dayTimePeriodFormatter.dateFormat = "MMM dd YYYY hh:mm a"
            
            let dateString = dayTimePeriodFormatter.string(from: date)
            
            cell.textLabel?.text =  dateString
            
        }else{
            cell.textLabel?.text = "No sleep episodes recorded yet! Open the Watch app for sleep."

        }

        return cell
    }
    

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
 

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // send email with data here
    }

   

}
