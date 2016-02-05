//
//  TPError.swift
//  testrest
//
//  Created by Vratislav Kalenda on 23.07.15.
//  Copyright © 2015 Dominik Snopek. All rights reserved.
//

import Foundation

class CSError : NSError{
    
    static let CSASErrorDomain = "CSASErrorDomain"
    
    static let ErrorNoInternetConnection = 30
    static let ErrorNotAvailable = 50
    static let ErrorServerTemporarilyNotAvailable = 53
    static let ErrorResourceNotFound = 44
    static let ErrorAuthNeeded = 401
    static let ErrorNotAuthorized = 403
    
    static let ErrorGenericApiError = 100
    
    static let ErrorBadCredentials = 101
    static let ErrorBadProviderToken = 111
    static let ErrorJSONMappingFailed = 999
    
    static let ErrorQueryTooLarge = 1101
    static let ErrorInvalidEmail = 1102
    
    
    static let ErrorLocationDisabled = 1200
    
    static func withCode(code:Int) -> CSError
    {
        return CSError(domain: CSASErrorDomain, code: code, userInfo: nil)
    }
    
    func isNetworkRelated() -> Bool
    {
        return CSError.isNetworkRelated(self)
    }
    
    static func isNetworkRelated(error:NSError) -> Bool
    {
        if error.code == CSError.ErrorNoInternetConnection || error.code == CSError.ErrorServerTemporarilyNotAvailable {
            return true
        } else {
            return false
        }
    }
    
}