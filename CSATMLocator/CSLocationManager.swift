//
//  CSLocationManager.swift
//  CSATMLocator
//
//  Created by Filip Kirschner on 19/09/15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift

class CSLocationManager: NSObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var currentLocation = PublishSubject<CLLocationCoordinate2D>()
    var currentHeading = PublishSubject<Double>()
    
    override init()
    {
        locationManager = CLLocationManager()
        super.init()
        self.setupLocationManager()
        self.startUpdatingLocation()
        
    }
    
    func setupLocationManager()
    {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.headingFilter = CLLocationDegrees(15)
        
    }
    
    func startUpdatingLocation()
    {
        self.locationManager.startUpdatingLocation()
        self.locationManager.startUpdatingHeading()
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation)
    {
        currentLocation.on(Event.Next(newLocation.coordinate))
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading)
    {
        currentHeading.on(Event.Next(newHeading.trueHeading))
    }
    
}