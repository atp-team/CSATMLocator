//
//  CSNavigation.swift
//  CSATMLocator
//
//  Created by Filip Kirschner on 20/09/15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class CSNavigation{
    
    static func navigateTo(coordinates : CLLocationCoordinate2D?)
    {
        var latLonSegment = ""
        if let coord = coordinates{
            latLonSegment = "daddr=\(coord.latitude),\(coord.longitude)"
        }
        
        if canLaunchGoogleNav(){
            let url = "comgooglemaps-x-callback://?\(latLonSegment)&x-success=Applifting.CSATMLocator://?reached=true&x-source=CSATMLocator"
            let urlObject = NSURL(string:url)
            UIApplication.sharedApplication().openURL(urlObject!)
        }else{
            let url = "http://maps.apple.com/?\(latLonSegment)"
            let urlObject = NSURL(string:url)
            UIApplication.sharedApplication().openURL(urlObject!)
        }
    }
    
    static func canLaunchGoogleNav() -> Bool
    {
        let url = NSURL(string: "comgooglemaps-x-callback://")
        return UIApplication.sharedApplication().canOpenURL(url!)
    }
    
}