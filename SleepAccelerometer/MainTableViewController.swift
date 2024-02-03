
import UIKit
import CoreData
import MessageUI

class MainTableViewController: UITableViewController,MFMailComposeViewControllerDelegate {
  
  var savedEvents : [Double] = [] // Holder for saved sleep events
  var watchManager : WatchManager?
  let HEADER_HEIGHT : CGFloat = 30.0
  private let control = UIRefreshControl()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    getHealthPermissions()
    
    tableView.refreshControl = control
    tableView.refreshControl?.addTarget(self, action: #selector(refreshSleepEvents(_:)), for: .valueChanged)
    
    Task {
      savedEvents = try await SleepEvent.getAllEvents()
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    
    self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
  }
  
  func getHealthPermissions(){
    let healthHelper = HealthHelper()
    healthHelper.getHealthPermissions()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(true)
    Task {
      savedEvents = try await SleepEvent.getAllEvents()
      
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData() // Don't forget to reload the tableView to reflect the changes
      }
    }
  }
  
  @objc private func refreshSleepEvents(_ sender: Any) {
    Task {
      savedEvents = try await SleepEvent.getAllEvents()
      
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.control.endRefreshing()
      }
    }
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
    
    let headerView = UIView()
    headerView.backgroundColor = UIColor.darkGray
    
    let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: HEADER_HEIGHT))
    titleLabel.font = UIFont.systemFont(ofSize: 12.0)
    titleLabel.textColor = UIColor.white
    
    let subtitleText = "Select row to export data"
    let attributes = [NSAttributedString.Key.kern : 2.0]
    titleLabel.attributedText = NSAttributedString(string: subtitleText.uppercased(), attributes: attributes as [NSAttributedString.Key : Any])
    titleLabel.textAlignment = .center
    
    headerView.addSubview(titleLabel)
    
    return headerView
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return HEADER_HEIGHT
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath)
    cell.textLabel?.text = stringFromEpoch(savedEvents[indexPath.row])
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      // Retrieve the startTime for the event to be deleted
      let startTime = savedEvents[indexPath.row]
      tableView.isUserInteractionEnabled = false
      
      Task {
        do {
          _ = try await SleepEvent.deleteAccelerationFor(startTime: startTime)
          
          DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.savedEvents.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
          }
        } catch {
          print("Error deleting sleep event: \(error)")
        }
      }
      // Re-enable user interaction on the main thread after update
      DispatchQueue.main.async {
        tableView.isUserInteractionEnabled = true
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // Disable user interaction to prevent further selection
    tableView.isUserInteractionEnabled = false
    let selectedEvent = savedEvents[indexPath.row]
    
    Task {
      let acceleration = try await SleepEvent.getAccelerationFor(startTime: selectedEvent)
      if acceleration.count > 0 {
        let heartRateHandler = HeartRateHandler()
        let startDate = Date(timeIntervalSince1970: selectedEvent)
        let accelItem = acceleration.last
        let endDate = Date(timeIntervalSince1970: accelItem?[0] ?? 0)
        
        let fileNameHR = "\(Int(savedEvents[indexPath.row]))_hr.csv"
        let pathHR = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileNameHR)
        
        // Save HR as a file, then save acceleration and send both as attachments
        heartRateHandler.retrieveHeartRate(start: startDate, end: endDate, path: pathHR) {
          DispatchQueue.main.async { [weak self] in
            // Ensure to re-enable user interaction after the async operation and UI update
            self?.tableView.isUserInteractionEnabled = true
            
            // Call function to handle UI update or further processing
            self?.exportMotionAndSendEmail(epochTime: selectedEvent, data: acceleration)
          }
        }
      } else {
        // If no acceleration data, re-enable interaction immediately
        DispatchQueue.main.async { [weak self] in
          self?.tableView.isUserInteractionEnabled = true
        }
      }
    }
  }
  
  func stringFromEpoch(_ epochTime : Double) -> String{
    let date = Date(timeIntervalSince1970: epochTime)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM dd YYYY hh:mm a"
    let dateString = dateFormatter.string(from: date)
    return dateString
  }
  
  func exportMotionAndSendEmail(epochTime: Double, data: [[Double]]){
    
    let epochTimeString = "\(Int(epochTime))"
    
    let fileName = epochTimeString + "_acceleration.csv" // Motion data
    let hrFileName = epochTimeString + "_hr.csv" // HR data
    
    let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
    let hrPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(hrFileName)
    
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
        // Uncomment to send email with paths for CSV files
        // sendEmail(dateString: stringFromEpoch(epochTime), path: path!, hr_path: hrPath!)
        shareData(paths: [path!.absoluteURL, hrPath!.absoluteURL])
        
      } catch {
        print("Unable to create file")
        print("\(error)")
      }
      
    } else {
      print("No data to export")
    }
  }
  
  func shareData(paths: [URL]) {
    var activityItems: [URL] = []
    for path in paths{
      if let _ = NSData(contentsOf: path) {
        activityItems.append(path.absoluteURL)
      } else {
        print("Unable to read file")
      }
    }
    
    let activity = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    present(activity, animated: true, completion: nil)
  }
  
  // Send email with attached CSV files
  func sendEmail(dateString: String, path: URL, hr_path: URL) {
    
    let composeVC = MFMailComposeViewController()
    composeVC.mailComposeDelegate = self
    
    composeVC.navigationBar.tintColor  = .white
    composeVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    
    // Configure email
    composeVC.setSubject("Sleep event data for " + dateString)
    composeVC.setMessageBody("Sleep event data attached as CSV", isHTML: false)
    
    if let fileData = NSData(contentsOf: path) {
      print("Motion data loaded.")
      composeVC.addAttachmentData(fileData as Data, mimeType: "text/csv", fileName: "motion_data.csv")
    }
    
    if let fileData = NSData(contentsOf: hr_path) {
      print("HR data loaded.")
      composeVC.addAttachmentData(fileData as Data, mimeType: "text/csv", fileName: "hr_data.csv")
    }
    
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
