//
//  AppDelegate.swift
//  PubNubHeartRateDemo
//
//  Created by Vijendra-New_Mac on 27/04/18.
//  Copyright © 2018 Vijendra-New_Mac. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PNObjectEventListener {

    var window: UIWindow?
    
    var client:PubNub?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let config = PNConfiguration(publishKey: "pub-c-1b4f0648-a1e6-4aa1-9bae-aebadf76babe", subscribeKey: "sub-c-e9fadae6-f73a-11e4-af94-02ee2ddab7fe")
        
        self.client = PubNub.clientWithConfiguration(config)
        
        self.client?.addListener(self)
        
        return true
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
  
    func client(_ client: PubNub, didReceive status: PNStatus) {
        if status.category == .PNDisconnectedCategory {
            // This event happens when radio / connectivity is lost
        }else if status.category == .PNConnectedCategory {
            // Connect event. You can do stuff like publish, and know you'll get it.
            // Or just use the connected event to confirm you are subscribed for
            // UI / internal notifications, etc
            client.publish("Hello from the PubNub Objective-C SDK", toChannel: "my_channel", withCompletion: {(_ status: PNPublishStatus?) -> Void in
                // Check whether request successfully completed or not.
                if status?.isError == nil {
                    // Message successfully published to specified channel.
                } else {
                    // Handle message publish error. Check 'category' property to find out possible issue
                    // because of which request did fail.
                    //
                    // Request can be resent using: [status retry];
                }
            })
        }else if (status.category == .PNReconnectedCategory) {
            
            // Happens as part of our regular operation. This event happens when
            // radio / connectivity is lost, then regained.
        }
        else if (status.category == .PNDecryptionErrorCategory) {
            
            // Handle messsage decryption error. Probably client configured to
            // encrypt messages and on live data feed it received plain text.
        }

    }
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        // Handle new message stored in message.data.message
        
        if (message.data.actualChannel != nil) {
            // Message has been received on channel group stored in
            // message.data.subscribedChannel
        } else {
            // Message has been received on channel stored in
            // message.data.subscribedChannel
        }
        print("Received message: \(message.data.message) on channel \(message.data.subscribedChannel) at \(message.data.timetoken)")
    }
    
    func publish(onPubNub PulseRate: String?, docId Docid: String?)
    {
        
        var DocId = "\(Docid)heartbeat_alert"
        
        
        self.client?.publish(PulseRate, toChannel: DocId, storeInHistory: true, withCompletion: { (status) in
            
        })
    }
    
}

