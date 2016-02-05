//
//  Api.swift
//  testrest
//
//  Created by Dominik Snopek on 20/07/15.
//  Copyright © 2015 Dominik Snopek. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift
import CoreLocation

/// By design, nearly all callbacks are invoked from background thread. It is a responsibility of a caller to ensure proper serialization and invocation of the code on main thread if necesarry
class ApiClient{
    
    
    let apiManager: ApiManager
    
    
    init(apiManager: ApiManager)
    {
        self.apiManager = apiManager
    }
 
    func getAtms(location : CLLocationCoordinate2D,limit:Int,bankCode:String?) -> Observable<[ATM]>
    {
        return Observable.create{ observer in
            self.apiManager.rxCall(Alamofire.Method.GET, url: ATM.atmsUrl , parameters: ["limit" : limit,"lat":location.latitude,"lng":location.longitude], payload: nil).subscribeNext { (resp,json) in
                observer.on(self.mapApiObjects(json) as Event<[ATM]>)
                observer.onCompleted()
            }
        }
    }
    
    private func mapApiObjects<T : ResponseObjectSerializable>(json : JSON) -> Event<[T]>
    {
        if let object = json.toApiObjectCollection() as [T]?{
            
            return Event.Next(object)
        }else{
            
            return Event.Error(CSError.withCode(CSError.ErrorJSONMappingFailed))
        }
    }
    
    private func mapApiObject<T : ResponseObjectSerializable>(json : JSON) -> Event<T>
    {
        if let object = json.toApiObject() as T?{
            
            return Event.Next(object)
        }else{
            
            return Event.Error(CSError.withCode(CSError.ErrorJSONMappingFailed))
        }
    }
    
}
