//
//  AppDelegate.swift
//  CSATMLocator
//
//  Created by Vratislav Kalenda on 16.09.15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import UIKit
import RxSwift
import CoreLocation
import WatchConnectivity



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    
    var window: UIWindow?
    private var apiClient: ApiClient!
    private var locationManager: CSLocationManager!
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        apiClient = ApiClient(apiManager: ApiManager())
        locationManager = CSLocationManager()
        
        initWatchCommunication()
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let main = CSViewController(nibName: "CSViewController", bundle: nil)
        main.apiClient = apiClient
        main.locationManager = locationManager
        window?.rootViewController = main
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func initWatchCommunication(){
        
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            self.getNewData()
        }
    }
    
    func getNewData(){
        locationManager.currentLocation.take(1).subscribeNext({
            userLocation in
            self.apiClient.getAtms(userLocation, limit: 10, bankCode: nil).take(1).subscribeNext({ (places: [ATM]) in
                if places.count > 0 {
                    
                    self.sendDataToWatch([
                        "name": places[0].name,
                        "address": places[0].address,
                        "alat": places[0].location.coordinate.latitude,
                        "alon": places[0].location.coordinate.longitude,
                        "ulat": userLocation.latitude,
                        "ulon": userLocation.longitude])
                } else {
                    
                    self.sendDataToWatch([
                        "error": "No atms nearby"])
                }
            })
        })
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject])
    {
        self.getNewData()
    }
    
    func sendDataToWatch(data: [String : AnyObject])
    {
        if WCSession.defaultSession().reachable {
            WCSession.defaultSession().sendMessage(data, replyHandler: nil, errorHandler: nil)
        }
    }
    
    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: ([NSObject : AnyObject]?) -> Void) {
        reply(nil)
    }
    
}

