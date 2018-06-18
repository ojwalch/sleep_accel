
import UIKit
import CoreData
import MessageUI

class MainTableViewController: UITableViewController,MFMailComposeViewControllerDelegate {
    
    var savedEvents : [Double] = [] // Holder for saved sleep events
    var watchManager : WatchManager?
    let HEADER_HEIGHT : CGFloat = 30.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get permissions
        let healthHelper = HealthHelper()
        healthHelper.getHealthPermissions()
        
        savedEvents = SleepEvent.getAllEvents()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        savedEvents = SleepEvent.getAllEvents()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedEvents.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        // Format header
        let headerView = UIView()
        headerView.backgroundColor = UIColor.darkGray
        
        let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: HEADER_HEIGHT))
        
        titleLabel.font = UIFont.systemFont(ofSize: 12.0)
        titleLabel.textColor = UIColor.white
        
        let subtitleText = "Select row to email data"
        
        let attributes = [NSAttributedStringKey.kern : 5.0]
        titleLabel.attributedText = NSAttributedString(string: subtitleText.uppercased(), attributes: attributes as [NSAttributedStringKey : Any])
        titleLabel.textAlignment = .center
        titleLabel.textAlignment = .center
        
        // Add label to view
        headerView.addSubview(titleLabel)
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HEADER_HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath)
        
        // Get date from saved event
        let date = Date(timeIntervalSince1970: savedEvents[indexPath.row])
        
        // Format it
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd YYYY hh:mm a"
        let dateString = dateFormatter.string(from: date)
        
        cell.textLabel?.text =  dateString
        
        return cell
    }
    
    // Set all rows to be editable
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Delete the row from the data source
            SleepEvent.deleteAccelerationFor(startTime : savedEvents[indexPath.row])
            
            // Delete from savedEvents
            savedEvents.remove(at: indexPath.row)
            
            // Remove from TableView
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Get motion data for sleep episode
        let acceleration = SleepEvent.getAccelerationFor(startTime: savedEvents[indexPath.row])
        
        // Get HR in range
        let heartRateHandler = HeartRateHandler()
        let startDate = Date(timeIntervalSince1970: savedEvents[indexPath.row]);
        let accelItem = acceleration[acceleration.count - 1];
        let endDate = Date(timeIntervalSince1970: accelItem[0]);
        
        let fileNameHR = "\(Int(savedEvents[indexPath.row]))" + "_hr.csv"
        let pathHR = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileNameHR)
        
        heartRateHandler.retrieveHeartRate(start: startDate, end: endDate, path: pathHR) // TODO: Make sure this is done before the email gets sent
        
        exportAsCSV(dateString:"\(Int(savedEvents[indexPath.row]))" , data: acceleration)
        
    }
    
    func exportAsCSV(dateString: String, data: [[Double]]){
        
        let fileName = dateString + ".csv" // Motion data
        let hr_fileName = dateString + "_hr.csv" // HR data
        
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let hr_path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(hr_fileName)
        
        var csvText = "Timestamp,x,y,z\n"
        
        let count = data.count
        
        if count > 0 {
            for i in 0 ..< data.count {
                
                let item = data[i]
                let newLine = "\(item[0]),\(item[1]),\(item[2]),\(item[3])\n"
                
                csvText.append(newLine)
            }
            
            do {
                try csvText.write(to: path!, atomically: true, encoding: String.Encoding.utf8)
                
                // Send email with paths for CSV files
                sendEmail(path: path!, hr_path: hr_path!)
                
            } catch {
                
                print("Unable to create file")
                print("\(error)")
            }
            
        } else {
            print("No data to export")
        }
        
    }
    
    
    // Send email with attached CSV files
    func sendEmail(path: URL, hr_path: URL) {
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.navigationBar.tintColor  = .white
        composeVC.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        
        
        // Configure email
        // composeVC.setToRecipients(["your@email.here"])
        composeVC.setSubject("Sleep event data")
        composeVC.setMessageBody("Sleep event data attached as CSV", isHTML: false)
        
        
        if let fileData = NSData(contentsOf: path) {
            print("Motion data loaded.")
            composeVC.addAttachmentData(fileData as Data, mimeType: "text/csv", fileName: "motion_data.csv")
        }
        
        if let fileData = NSData(contentsOf: hr_path) {
            print("HR data loaded.")
            composeVC.addAttachmentData(fileData as Data, mimeType: "text/csv", fileName: "hr_data.csv")
        }
        
        // Present mail controller
        self.present(composeVC, animated: true, completion: nil)
        
    }
    
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func showEditing(sender: UIBarButtonItem)
    {
        if(self.tableView.isEditing == true)
        {
            self.tableView.isEditing = false
            self.navigationItem.rightBarButtonItem?.title = "Done"
        }
        else
        {
            self.tableView.isEditing = true
            self.navigationItem.rightBarButtonItem?.title = "Edit"
        }
    }
    
}
