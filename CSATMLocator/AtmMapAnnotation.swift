//
//  AtmMapAnnotation.swift
//  CSATMLocator
//
//  Created by Marty on 08/02/16.
//  Copyright © 2016 Vratislav Kalenda. All rights reserved.
//

import MapKit


class AtmMapAnnotation: NSObject, MKAnnotation {
   
    let title: String?
    let subtitle: String?

    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String,  coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = locationName
        self.coordinate = coordinate
        
        super.init()
    }

}