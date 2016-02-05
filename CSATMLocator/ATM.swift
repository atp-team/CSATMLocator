//
//  ATM.swift
//  CSATMLocator
//
//  Created by Vratislav Kalenda on 16.09.15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import Foundation
import CoreLocation


enum PlaceType : String{
    case Branch = "BRANCH"
    case ATM = "ATM"
}

enum PlaceState : String{
    case Open = "OPEN"
    case Closed = "CLOSED"
    case OutOfOrder = "OUT_OF_ORDER"
}

class ATM : ResponseObjectSerializable{
//    services	Service list	list of services, like qmatic support or wifi
//    openingHours	OpeningHour list	opening hours for each day
    
    let id : String //id of the Branch or ATM
    let location : CLLocation //location - latitude, longitude, accuracy
    let type : PlaceType //type of the place
//    let state : PlaceState //place state. It does not reflect the instant state according to opening hours. It rather means general (long-term) status: if it normaly works, state is OPEN. If it is short-term out of order due tu e.g. service works, then it is OUT_OF_ORDER and in stateNote field there are more details. If it is long-term closed (e.g. cancelled), then it is CLOSED.
    let stateNote : String?
    var distance : Int?
    let name : String
    let address : String
    let city : String
    let postCode : String
    let country : String? //2-letter uppercased country code according to ISO 3166-1 alpha-2
    let bankCode : String
    let accessType : String

    
    required init?(json: JSON) {
        
        
        var location : CLLocation!
        let id = json["id"].intValue
        let accuracy = json["location.accuracy"].int
        guard
            let lat = json["location"]["lat"].double,
            let lng = json["location"]["lng"].double,
            
            let name = json["name"].string,
            let address = json["address"].string,
            let city = json["city"].string,
            let postCode = json["postCode"].string,
//            let stateString = json["state"].string,
//            let state = PlaceState(rawValue: stateString),
            let typeString = json["type"].string,
            let type = PlaceType(rawValue: typeString),
            let bankCode = json["bankCode"].string,
            let accessType = json["accessType"].string
        else{
            self.id = ""
            self.location = CLLocation()
            self.name = ""
            self.type = .ATM
//            self.state = .Open
            self.stateNote = nil
            self.address = ""
            self.city = ""
            self.postCode = ""
            self.country = nil
            self.distance = nil
            self.bankCode = ""
            self.accessType = ""
            return nil
        }
        
        if accuracy != nil {
            location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: lat,longitude: lng), altitude: 0, horizontalAccuracy: Double(accuracy!), verticalAccuracy: 0, timestamp: NSDate())
        } else {
            location = CLLocation(latitude: lat, longitude: lng)
        }
        self.distance = json["distance"].int
        self.address = address
        self.city = city
        self.postCode = postCode
        self.country = nil
        self.stateNote = nil
        self.location = location
        self.id = "place_\(id)"
        self.name = name
        self.type = type
//        self.state = state
        self.bankCode = bankCode
        self.accessType = accessType
    }
}

extension ATM {
    
    static let atmsUrl : String = WebApi.baseURL + "/places/atms"
}
