//
//  ViewController.swift
//  PinchPad
//
//  Created by Ryan Laughlin on 2/2/15.
//
//

import UIKit
import TwitterKit
import TMTumblrSDK
import Locksmith
import SwiftyJSON

class ViewController: UIViewController{
    @IBOutlet var canvas: PPInfiniteScrollView!
    @IBOutlet var toolConfigurationViewContainer: UIView!
    @IBOutlet var menuViewContainer: UIView!
    @IBOutlet var pendingPostsView: UIView!
    @IBOutlet var pendingPostsLabel: UILabel!
    @IBOutlet var pendingPostsRetryButton: UIButton!
    
    @IBOutlet var pencilButton: UIBarButtonItem!
    @IBOutlet var eraserButton: UIBarButtonItem!
    
    var lastTool = PPToolType.Brush
   
    override func viewDidLoad() {
        // When our data changes, update the display
        self.updatePendingPostsDisplay()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updatePendingPostsDisplay"), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
        
        // When our tool changes, update the display
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateToolbarDisplay"), name: "PPToolConfigurationChanged", object: nil)
        
        // Clear canvas when we are told to
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clear"), name: "PPClearCanvas", object: nil)
        
        super.viewDidLoad()
    }
    
    
    // MARK: tool handling
    
    @IBAction func menu(){
        toolConfigurationViewContainer.hidden = true
        menuViewContainer.hidden = !menuViewContainer.hidden
    }
    
    @IBAction func pencil(){
        menuViewContainer.hidden = true
        if (PPToolConfiguration.sharedInstance.tool != .Eraser){
            // Toggle config menu if the pencil or brush is already selected
            toolConfigurationViewContainer.hidden = !toolConfigurationViewContainer.hidden
        } else {
            // Otherwise, switch to last tool
            PPToolConfiguration.sharedInstance.tool = lastTool
        }
    }
    
    @IBAction func eraser(){
        menuViewContainer.hidden = true
        if (PPToolConfiguration.sharedInstance.tool == .Eraser){
            // Toggle config menu if the eraser is already selected
            toolConfigurationViewContainer.hidden = !toolConfigurationViewContainer.hidden
        } else {
            // Otherwise, switch to eraser (but remember what tool we were using last)
            lastTool = PPToolConfiguration.sharedInstance.tool
            PPToolConfiguration.sharedInstance.tool = .Eraser
        }
    }
    
    @IBAction func undo(){
        self.canvas.undo()
    }
    
    @IBAction func redo(){
        self.canvas.redo()
    }
    
    @IBAction func post(){
        // Some code based on https://twittercommunity.com/t/upload-images-with-swift/28410/7
        let image = self.canvas.contentView.asImage()
        
        // Don't post if we haven't drawn any strokes
        if (self.canvas.contentView.strokes.count == 0){
            var alert = UIAlertController(title: "Your sketch is blank", message: "You haven't drawn anything yet, silly!", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        } else if (AuthManager.loggedInServices().count == 0){
            var alert = UIAlertController(title: "No accounts configured", message: "In order to post a sketch, please tap the 'Menu' button and connect your Twitter or Tumblr account.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        // Format the date
        let date = NSDate(), dateFormatter = NSDateFormatter(), timeFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        timeFormatter.dateFormat = "h:mma"
        let caption = "\(dateFormatter.stringFromDate(date)), \(timeFormatter.stringFromDate(date).lowercaseString)"
        
        // Actually post
        for service in AuthManager.loggedInServices(){
            println("Posting to service #\(service.rawValue+1)")
            AuthManager.enqueue(service, image: image, caption: caption)
        }
        
        // Clear the canvas
        self.canvas.clear()
    }
    
    
    // MARK: Other menu-related functions
    
    func clear(){
        self.canvas.clear()
        self.menuViewContainer.hidden = true
    }
    
    
    // MARK: Pending post display handling
    
    func updatePendingPostsDisplay(){
        let fetchRequest = NSFetchRequest(entityName: "Sketch")
        fetchRequest.predicate = NSPredicate(format: "syncStarted == nil AND duration = 0", NSDate().dateByAddingTimeInterval(-60))
        let unsynced = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil)
        
        fetchRequest.predicate = NSPredicate(format: "syncError == true AND duration = 0")
        let syncErrors = AuthManager.managedContext().executeFetchRequest(fetchRequest, error: nil)
        
        if let syncErrors = syncErrors where syncErrors.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = false
            var pluralPosts = (syncErrors.count == 1 ? "post" : "posts")
            pendingPostsLabel.text = "\(syncErrors.count) \(pluralPosts) failed to sync"
        } else if let unsynced = unsynced where unsynced.count > 0{
            pendingPostsView.alpha = 1
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Posting..."
        } else {
            pendingPostsRetryButton.hidden = true
            pendingPostsLabel.text = "Post submitted!"
            UIView.animateWithDuration(0.5, delay: 2.0, options: nil, animations: { () -> Void in
                self.pendingPostsView.alpha = 0
            }, completion: nil)
        }
    }
    
    @IBAction func retry(){
        AuthManager.sync()
    }
    
    
    // MARK: Toolbar display handling
    
    func updateToolbarDisplay(){
        if (PPToolConfiguration.sharedInstance.tool == .Eraser){
            pencilButton.tintColor = UIColor.lightGrayColor()
            eraserButton.tintColor = self.view.tintColor
        } else {
            pencilButton.tintColor = self.view.tintColor
            eraserButton.tintColor = UIColor.lightGrayColor()
        }
    }
}