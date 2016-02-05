//
//  ApiManager.swift
//  testrest
//
//  Created by Vratislav Kalenda on 20/07/15.
//  Copyright © 2015 Vratislav Kalenda. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift


public protocol ResponseObjectSerializable
{
    init?(json: JSON)
}

public protocol JSONObjectSerializable
{
    func toJSON() -> JSON
}

public protocol ResponseCollectionSerializable
{
    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Self]
}

extension JSON : JSONObjectSerializable
{
    public func toJSON() -> JSON {
        return self
    }
}

extension Request {
    
    /**
     Adds a handler to be called once the request has finished.
     
     :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the SwiftyJSON enum, if one could be created from the URL response and data, and any error produced while creating the SwiftyJSON enum.
     
     :returns: The request.
     */
    public func responseSwiftyJSON(completionHandler: (NSURLRequest, NSHTTPURLResponse?, JSON, NSError?) -> Void) -> Self
    {
        return responseSwiftyJSONQ(nil, options:NSJSONReadingOptions.AllowFragments, completionHandler:completionHandler)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     :param: queue The queue on which the completion handler is dispatched.
     :param: options The JSON serialization reading options. `.AllowFragments` by default.
     :param: completionHandler A closure to be executed once the request has finished. The closure takes 4 arguments: the URL request, the URL response, if one was received, the SwiftyJSON enum, if one could be created from the URL response and data, and any error produced while creating the SwiftyJSON enum.
     
     :returns: The request.
     */
    public func responseSwiftyJSONQ(queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (NSURLRequest, NSHTTPURLResponse?, JSON, NSError?) -> Void) -> Self {
        response(queue: queue, responseSerializer: Request.JSONResponseSerializer(options: options)) { (response) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                var error : NSError?
                let errorFromResponse = self.handleErrors(response.response, error: response.result.error)
                if(errorFromResponse != nil){
                    error = errorFromResponse
                }
                
                var responseJSON: JSON
                if errorFromResponse != nil || response.result.value == nil{
                    responseJSON = JSON.null
                } else {
                    responseJSON = JSON(response.result.value!)
                }
                
                dispatch_async(queue ?? dispatch_get_main_queue(), {
                    completionHandler(self.request!, self.response, responseJSON, error)
                })
            })
        }
        return self
    }
    
    private func handleErrors(resp: NSHTTPURLResponse?, error : NSError?) -> NSError?
    {
        if error != nil{
            if  error!.code == NSURLErrorTimedOut ||
                error!.code == NSURLErrorNetworkConnectionLost ||
                error!.code == NSURLErrorCannotFindHost ||
                error!.code == NSURLErrorNotConnectedToInternet ||
                error!.code == NSURLErrorDNSLookupFailed ||
                error!.code == NSURLErrorCannotConnectToHost {
                    
                    return CSError.withCode(CSError.ErrorNoInternetConnection)
            }
        }
        
        if resp?.statusCode == 503 {
            return CSError.withCode(CSError.ErrorServerTemporarilyNotAvailable)
        }else if resp?.statusCode == 404 {
            return CSError.withCode(CSError.ErrorResourceNotFound)
        }else if resp?.statusCode  >= 500 && resp?.statusCode <= 500 {
            return CSError.withCode(CSError.ErrorNotAvailable)
        }else if resp?.statusCode == 401 {
            return CSError.withCode(CSError.ErrorAuthNeeded)
        }else if resp?.statusCode == 403 {
            return CSError.withCode(CSError.ErrorNotAuthorized)
        }
        
        return nil
    }
    
}

//
class ApiManager {
    
    static let callbackQueue = dispatch_queue_create("Api.Callback.Queue", DISPATCH_QUEUE_CONCURRENT)
    
    static let baseURL = "https://api.csas.cz/sandbox/webapi/api/v2"
    
    static let sharedInstance: Manager = {
        var defaultHeaders = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? ["WEB-API-key":AppDelegate.WEB_API_KEY]
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHeaders

        
        return Alamofire.Manager(configuration: configuration)
    }()
    
    
    func rxCall(method: Alamofire.Method,url: String, parameters: [String: AnyObject]?,payload: JSONObjectSerializable?) -> Observable<(respone:NSHTTPURLResponse!,json:JSON!)>
    {
        return Observable.create { observer in
            let request = self.call(method, url: url, parameters: parameters, payload: payload)
            request.responseSwiftyJSONQ(ApiManager.callbackQueue, options: .AllowFragments, completionHandler: { (request, response, json, error) -> Void in
                if((json == JSON.null || json != nil) && error == nil){
                    observer.onNext((response,json))
                    observer.onCompleted()
                }else{
                    observer.onError(error ?? NSError(domain: "CSATMError", code: 0, userInfo: nil))
                }
                }
            )
            return AnonymousDisposable {
                request.cancel()
            }
        }
        
    }
    
    func call(method: Alamofire.Method,url: String, parameters: [String: AnyObject]?,payload: JSONObjectSerializable?) -> Request
    {
        let URL = NSURL(string: url)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = method.rawValue
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if payload != nil {
            do{
                let json = payload!.toJSON()
                print("request body: \(json.debugDescription)")
                try mutableURLRequest.HTTPBody = json.rawData()
                
            }catch {
                print("Serialization failed")
                
            }
        }
        let encodingResult = ParameterEncoding.URL.encode(mutableURLRequest, parameters: parameters)
        mutableURLRequest.URL = encodingResult.0.URL
        let request = ApiManager.sharedInstance.request(mutableURLRequest)
        return request.response(completionHandler: { (request, resp :NSHTTPURLResponse?, _, error) -> Void in
            print("Call completed with \(resp.debugDescription) \(request.debugDescription)")
        })
    }
    
}


extension JSON{
    
    func toApiObject<T: ResponseObjectSerializable>()->T?
    {
        do{
            let realType = T.self
            return realType.init(json: self)
        }
    }
    
    func toApiObjectCollection<T: ResponseObjectSerializable>() -> [T]?
    {
        let realType = T.self
        if let array = self.array{
            var resultArray = [T]()
            for jsonEntry in array{
                if let manifestedEntity = realType.init(json: jsonEntry){
                    resultArray.append(manifestedEntity)
                }
            }
            return resultArray
        }
        return nil
    }
    
}
