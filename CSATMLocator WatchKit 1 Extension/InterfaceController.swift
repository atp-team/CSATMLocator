//
//  InterfaceController.swift
//  CSATMLocator WatchKit 1 Extension
//
//  Created by Filip Kirschner on 19/09/15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import WatchKit
import Foundation
import MapKit
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    @IBOutlet var label: WKInterfaceLabel!
    @IBOutlet var map: WKInterfaceMap!
    @IBOutlet var nameLabel: WKInterfaceLabel!
    @IBOutlet var addressLabel: WKInterfaceLabel!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    func initWatchCommunication()
    {
        if WCSession.isSupported() {
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            self.requestData()
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject])
    {
        if message["error"] == nil{
            if let name = message["name"] as? String,
                address = message["address"] as? String,
                alat = message["alat"] as? Double,
                alon = message["alon"] as? Double,
                ulat = message["ulat"] as? Double,
                ulon = message["ulon"] as? Double {
            self.nameLabel.setText(name)
            self.addressLabel.setText(address)
            let latDelta = ulat - alat
            let lonDelta = ulon - alon
            self.map.removeAllAnnotations()
            //Add user annotation
            self.map.addAnnotation(CLLocationCoordinate2D(latitude: ulat, longitude: ulon), withImage: UIImage(named: "marker"), centerOffset: CGPoint(x: 0, y: -12))
            //Add ATM annotation
            self.map.addAnnotation(CLLocationCoordinate2D(latitude: alat, longitude: alon), withImage: UIImage(named: "markerATM"), centerOffset: CGPoint(x: 0, y: -12))
            //Set reasonable region bounds
            self.map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: ulat - latDelta*(latDelta < 0 ? 2/3 : 1/3), longitude: ulon - lonDelta/2), span: MKCoordinateSpanMake(abs(latDelta*1.6), abs(lonDelta*1.6))))
            }else{
                self.nameLabel.setText("Data corrupted")
            }
        }else{
            self.nameLabel.setText(message["error"] as? String)
        }
    }
    
    override func willActivate()
    {
        initWatchCommunication()
        self.requestData()
        super.willActivate()
    }
    
    func sendDataToPhone(data: [String : AnyObject])
    {
        if WCSession.defaultSession().reachable {
            WCSession.defaultSession().sendMessage(data, replyHandler: nil, errorHandler: nil)
        }
    }
    
    func requestData()
    {
        sendDataToPhone([
            "command": "data request"])
    }

    override func didDeactivate()
    {
        super.didDeactivate()
    }

}
