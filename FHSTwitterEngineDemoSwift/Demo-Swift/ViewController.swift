//
//  ViewController.swift
//  Demo-Swift
//
//  Created by Daniel Khamsing on 1/14/15.
//  Copyright (c) 2015 dkhamsing. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, FHSTwitterEngineAccessTokenDelegate, UIAlertViewDelegate  {
    
    let dataSource = [
        "Post Tweet",
        "Timeline",
        "Logout",
    ]
    
    let cellId = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Demo"
        
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        let oauthButton = UIBarButtonItem(title: "OAuth", style: UIBarButtonItemStyle.Plain, target: self, action: "oauthAction")
        self.navigationItem.rightBarButtonItem = oauthButton
        
        FHSTwitterEngine.sharedEngine().permanentlySetConsumerKey("Xg3ACDprWAH8loEPjMzRg", andSecret: "9LwYDxw1iTc6D9ebHdrYCZrJP4lJhQv5uf4ueiPHvJ0")
        FHSTwitterEngine.sharedEngine().delegate = self
        FHSTwitterEngine.sharedEngine().loadAccessToken()        
    }
    
    // MARK: - Private
    
    func oauthAction() {
        
        let loginController = FHSTwitterEngine.sharedEngine().loginControllerWithCompletionHandler { (Bool success) -> Void in
            print("success: \(success) \n")
        }
        
        self.presentViewController(loginController, animated: true, completion: nil)
    }
    
    // MARK: - UITableView
    
    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return FHSTwitterEngine.sharedEngine().isAuthorized() ? self.dataSource.count : self.dataSource.count - 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        
        let action = self.dataSource[indexPath.row] as String
        
        cell.textLabel?.text = "\(action)"
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            print("post tweet")
            let alertView = UIAlertView(title: "Tweet", message: "Write a tweet below", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Tweet")
            alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
            alertView.show()
            
        case 1:
            print("time line")
            print("\(FHSTwitterEngine.sharedEngine().getTimelineForUser(FHSTwitterEngine.sharedEngine().authenticatedID, isID: true, count: 10))")

        case 2:
            FHSTwitterEngine.sharedEngine().clearAccessToken()
            self.tableView.reloadData()
            
        default:
            let row = indexPath.row
            print("tapped on \(row) \n")
            
        }
        
    }
    
    // MARK: - AlertView
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {

        if (alertView.title == "Tweet") {
            let tweet = alertView.textFieldAtIndex(0)?.text
            // TODO: validate input
            FHSTwitterEngine.sharedEngine().postTweet(tweet)
            // TODO: check return (error)
        }
    }
    
    // MARK: - FHSTwitterEngine
    
    func storeAccessToken(accessToken: String!) {
        NSUserDefaults.standardUserDefaults().setObject(accessToken, forKey: "SavedAccessHTTPBody")
    }
    
    func loadAccessToken() -> String! {
        return NSUserDefaults.standardUserDefaults().objectForKey("SavedAccessHTTPBody") as String
    }
}

