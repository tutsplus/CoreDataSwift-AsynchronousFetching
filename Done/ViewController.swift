//
//  ViewController.swift
//  Done
//
//  Created by Bart Jacobs on 19/10/15.
//  Copyright © 2015 Envato Tuts+. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let ReuseIdentifierToDoCell = "ToDoCell"
    
    @IBOutlet weak var tableView: UITableView!
    
    var managedObjectContext: NSManagedObjectContext!
    
    var items: [NSManagedObject] = []
    
    // MARK: -
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show Progress HUD
        SVProgressHUD.showWithStatus("Fetching Data", maskType: .Gradient)
        
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Item")
        
        // Add Sort Descriptors
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Dismiss Progress HUD
                SVProgressHUD.dismiss()
                
                // Process Asynchronous Fetch Result
                self.processAsynchronousFetchResult(asynchronousFetchResult)
                
                if let asynchronousFetchProgress = asynchronousFetchResult.progress {
                    // Remove Observer
                    asynchronousFetchProgress.removeObserver(self, forKeyPath: "completedUnitCount")
                }
            })
        }
        
        do {
            // Create Progress
            let progress = NSProgress(totalUnitCount: 1)
            
            // Become Current
            progress.becomeCurrentWithPendingUnitCount(1)
            
            // Execute Asynchronous Fetch Request
            let asynchronousFetchResult = try managedObjectContext.executeRequest(asynchronousFetchRequest) as! NSAsynchronousFetchResult
            
            if let asynchronousFetchProgress = asynchronousFetchResult.progress {
                asynchronousFetchProgress.addObserver(self, forKeyPath: "completedUnitCount", options: NSKeyValueObservingOptions.New, context: nil)
            }
            
            // Resign Current
            progress.resignCurrent()
            
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }
    
    // MARK: -
    // MARK: Prepare for Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SegueAddToDoViewController" {
            if let navigationController = segue.destinationViewController as? UINavigationController {
                if let viewController = navigationController.topViewController as? AddToDoViewController {
                    viewController.managedObjectContext = managedObjectContext
                }
            }
            
        } else if segue.identifier == "SegueUpdateToDoViewController" {
            if let viewController = segue.destinationViewController as? UpdateToDoViewController {
                if let indexPath = tableView.indexPathForSelectedRow {
                    // Fetch Record
                    let record = items[indexPath.row]
                    
                    // Configure View Controller
                    viewController.record = record
                    viewController.managedObjectContext = managedObjectContext
                }
            }
        }
    }
    
    // MARK: -
    // MARK: Table View Data Source Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ReuseIdentifierToDoCell, forIndexPath: indexPath) as! ToDoCell
        
        // Configure Table View Cell
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: ToDoCell, atIndexPath indexPath: NSIndexPath) {
        // Fetch Record
        let record = items[indexPath.row]
        
        // Update Cell
        if let name = record.valueForKey("name") as? String {
            cell.nameLabel.text = name
        }
        
        if let done = record.valueForKey("done") as? Bool {
            cell.doneButton.selected = done
        }
        
        cell.didTapButtonHandler = {
            if let done = record.valueForKey("done") as? Bool {
                record.setValue(!done, forKey: "done")
            }
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            // Fetch Record
            let record = items[indexPath.row]
            
            // Delete Record
            managedObjectContext.deleteObject(record)
        }
    }
    
    // MARK: -
    // MARK: Table View Delegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: -
    // MARK: Helper Methods
    func processAsynchronousFetchResult(asynchronousFetchResult: NSAsynchronousFetchResult) {
        if let result = asynchronousFetchResult.finalResult {
            // Update Items
            items = result as! [NSManagedObject]
            
            // Reload Table View
            tableView.reloadData()
        }
    }
    
    // MARK: -
    // MARK: Key Value Observing
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "completedUnitCount" {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let changes = change, number = changes["new"] {
                    // Create Status
                    let status = "Fetched \(number) Records"
                    
                    // Show Progress HUD
                    SVProgressHUD.setStatus(status)
                }
            })
        }
    }

}
