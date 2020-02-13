//
//  GKAppStoreConnectApi.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew Liakh on 28.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

public class GKAppStoreConnectApi {
    
    /*!
     @property        authServiceKey
     @abstract        Retrieved from App Store Connect API in @c -loginWithUsername:password:completionHandler:, this is used in every subsequent call to App Store Connect's API.
     */
    var authServiceKey: String = ""
    
    /*!
     @property        personID
     @abstract        Identifies the currently logged in user. Needed in @c -_switchToTeamWithID:completionHandler:
     */
    var personID: String?
    
    /*!
     @property        currentTeamID
     @abstract        Identifies the currently selected team. Needed in @c -_appsForCurrentTeamWithCompletionHandler:
     */
    var currentTeamID: Int?
    
    /*!
     @property        tfaAppleIDSessionID
     @abstract        Used during two-factor authorization, required as a header value
     */
    var tfaAppleIDSessionID: String?

    /*!
     @property        tfaScnt
     @abstract        Used during two-factor authorization, required as a header value
     */
    var tfaScnt: String?


    /*!
     @property        cachedTeams
     @abstract        The teams available to the user. Cached after login is complete and @c -_loadSessionDataAfterLoginWithCompletionHandler is called.
     */
    var cachedTeams = [ASCTeam]()
    
    /*!
     @property        userSession
     @abstract        The user session. Cached after login is complete and @c -_loadSessionDataAfterLoginWithCompletionHandler is called. Used to switch teams.
     */
    var userSession: [String: Any]?
    
    public var currentTeam: ASCTeam? {
        guard let teamId = currentTeamID, cachedTeams.count > 0 else {
            return nil
        }
        for team in cachedTeams {
            if team.providerId == teamId {
                return team
            }
        }
        return nil
    }
    
    private static let sharedInstance = GKAppStoreConnectApi()
    
    public static var shared: GKAppStoreConnectApi {
        return sharedInstance
    }
    
    private init() {}
    
    // MARK: - Login
    
    public func loginWith(username: String,
                   password: String,
                   completionHandler: @escaping ((_ loggedIn: Bool, _ needsTwoFactorAuth: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)) {
        
        if username.isEmpty || password.isEmpty {
            completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.malformedRequest.rawValue, userInfo: nil))
            return
        }
        
        //first, retrieve authServiceKey / Apple Widget Key
        let req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/olympus/v1/app/config?hostname=itunesconnect.apple.com")!)
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let data = data, let _ = response, error == nil else {
                completionHandler(false, false, nil, error)
                return
            }
            
            do {
                guard let retDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.badJson.rawValue, userInfo: nil))
                    return
                }
                
                self.authServiceKey = retDict["authServiceKey"] as? String ?? ""
                
                if self.authServiceKey.isEmpty {
                    completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.serviceKeyMissing.rawValue, userInfo: nil))
                    return
                }
                
                //now start actual sign in process
                let loginDict: [String: Any] = [
                    "accountName": username,
                    "password": password,
                    "rememberMe": true
                ]
                
                var req = URLRequest(url: URL(string: "https://idmsa.apple.com/appleauth/auth/signin")!)
                
                do {
                    let loginJson = try JSONSerialization.data(withJSONObject: loginDict, options: .prettyPrinted)
                    req.httpBody = loginJson
                    req.httpMethod = "POST"
                    req.httpShouldHandleCookies = true
                    
                    req = self.updateHeadersFor(request: req, additionalFields: [:])
                    
                    let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                        guard let resp = response as? HTTPURLResponse, let _ = data, error == nil else {
                            completionHandler(false, false, nil, error)
                            return
                        }
                        
                        if resp.statusCode == 409 {
                            //two-factor or two-step authentication in effect, auth-code possibly already sent to user (via push to device or sms to trusted number)
                            let scnt = resp.allHeaderFields["scnt"] as? String ?? ""
                            let xappleidsessionid = resp.allHeaderFields["X-Apple-ID-Session-Id"] as? String ?? ""
                            if scnt.isEmpty || xappleidsessionid.isEmpty {
                                completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                                return
                            }
                            
                            self.tfaScnt = scnt
                            self.tfaAppleIDSessionID = xappleidsessionid
                            
                            var req = URLRequest(url: URL(string: "https://idmsa.apple.com/appleauth/auth")!)
                            req.httpMethod = "GET"
                            
                            req = self.updateHeadersFor(request: req, additionalFields: [
                                "X-Apple-Id-Session-Id": self.tfaAppleIDSessionID ?? "",
                                "scnt": self.tfaScnt ?? ""
                            ])
                            
                            //request auth info from user
                            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                                guard let _ = response, let data = data, error == nil else {
                                    completionHandler(false, false, nil, error)
                                    return
                                }
                                
                                /*
                                There are, as far as I could test, four ways to go:
                                1) an error occurs - end
                                2) one phone number and no trusted devices are stored -> code sent via sms to phone number right away
                                    but need option to re-send code via sms
                                3) more than one phone number and no trusted devices -> code not automatically sent, needs selection of where to send code to
                                4) any number of phone numbers, but have trusted devices -> code sent to devices right away
                                    but need option to re-send code or send via sms
                                */
                                
                                do {
                                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                                    guard let dict = json as? [String: Any] else {
                                        completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                                        return
                                    }
//                                    print(dict)
                                    let trustedDevices = dict["trustedDevices"] as? [String: Any] ?? [String: Any]()
                                    var trustedPhoneNumbers = dict["trustedPhoneNumbers"] as? [[String: Any]] ?? [[String: Any]]()
                                    trustedPhoneNumbers.sort { (number1, number2) -> Bool in
                                        return (number1["id"] as? Int ?? 0) < (number2["id"] as? Int ?? 0)
                                    }
                                    
                                    let noTrustedDevices = dict["noTrustedDevices"] as? Bool ?? false
                                    
                                    if (noTrustedDevices || trustedDevices.count == 0) && trustedPhoneNumbers.count == 0 {
                                        completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                                    }
                                    
                                    let securityCodeDict = dict["securityCode"] as? [String: Any] ?? [String: Any]()
                                    
                                    if securityCodeDict["securityCodeLocked"] as? Bool == true
                                    || securityCodeDict["tooManyCodesSent"] as? Bool == true
                                    || securityCodeDict["tooManyCodesValidated"] as? Bool == true {
                                        var code = GKASCAPIErrorCode.unexpectedReply
                                        
                                        if securityCodeDict["securityCodeLocked"] as? Bool == true {
                                            code = .securityCodeLocked
                                        } else if securityCodeDict["tooManyCodesSent"] as? Bool == true{
                                            code = .tooManyCodesSent
                                        } else if securityCodeDict["tooManyCodesValidated"] as? Bool == true{
                                            code = .tooManyCodesValidated
                                        }
                                        
                                        completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: code.rawValue, userInfo: nil))
                                        
                                        return
                                    }
                                    
                                    var infoDict: [String: Any] = [
                                        "securityCode": securityCodeDict,
                                        "phoneNumbers": trustedPhoneNumbers,
                                        "didSendCode": true,
                                        "wasTrustedDeviceCode": !noTrustedDevices,
                                        "scnt": self.tfaScnt ?? "",
                                        "AppleIDSessionID": self.tfaAppleIDSessionID ?? ""
                                    ]
                                    
                                    let trustedPhoneNumber = dict["trustedPhoneNumber"] as? [String: Any] ?? [String: Any]()
                                    
                                    if (trustedPhoneNumber["pushMode"] as? String == "sms"
                                    && trustedPhoneNumbers.count != 0
                                    && securityCodeDict.count != 0
                                    && noTrustedDevices) // an sms was sent
                                    || !noTrustedDevices // a code was pushed to the account's trusted devices
                                    {
                                        // code was sent right away
                                        if infoDict["wasTrustedDeviceCode"] as? Bool == false {
                                            infoDict["resendInfo"] = ["phoneID": trustedPhoneNumber["id"], "phoneNumber": trustedPhoneNumber["numberWithDialCode"]]
                                        }
                                        
                                        completionHandler(false, true, infoDict, nil)
                                        
                                        return
                                    }
                                    
                                    // the code was not sent right away, need to present the user with a selection for their preferred phone number
                                    
                                    infoDict["didSendCode"] = false
                                    
                                    completionHandler(false, true, infoDict, nil)
                                } catch let jsonError {
                                    completionHandler(false, false, nil, jsonError)
                                }
                            }
                            
                            task.resume()
                        } else if resp.statusCode != 200 {
                            // something else went wrong.
                            completionHandler(false, false, nil, error ?? NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                            return
                        }
                        
                        // we're already logged in - either 2FA is not enabled, or cookies are still valid from previous session
                        
                        do {
                            guard let data = data else {
                                throw NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil)
                            }
                            
                            let json = try JSONSerialization.jsonObject(with: data, options: []) //returns {"authType":"non-sa";}
                            
                            guard let dict = json as? [String: Any] else {
                                completionHandler(false, false, nil, error ?? NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                                return
                            }
                            
                            if dict["serviceErrors"] != nil {
                                NSLog("*** received an error - possibly login: \(String(describing: dict["serviceErrors"]))")
                                completionHandler(false, false, nil, error ?? NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                            }
                            
                            // retrieve session data (returns teams, apps and user)
                            
                            self.loadSessionDataAfterLoginWith { (info, error) in
                                if info == nil || error != nil {
                                    completionHandler(true, false, nil, error)
                                    return
                                }
                                
                                completionHandler(true, false, info, error)
                            }
                        } catch _ {
                            completionHandler(false, false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                        }
                    }
                    task.resume()
                } catch let jsonError {
                    completionHandler(false, false, nil, jsonError)
                }
            } catch let jsonError {
                completionHandler(false, false, nil, jsonError)
            }
        }
        task.resume()
    }
    
    public func resend2FACodeWith(phoneID: Int, completionHandler: @escaping ((_ resent: Bool, _ error: Error?) -> Void)) {
        let body: [String: Any] = [
            "phoneNumber": [
                "id": phoneID
            ],
            "mode": "sms"
        ]
        var req = URLRequest(url: URL(string: "https://idmsa.apple.com/appleauth/auth/verify/phone")!)
        req.httpMethod = "PUT"
        req = updateHeadersFor(request: req, additionalFields: [
            "X-Apple-Id-Session-Id": self.tfaAppleIDSessionID ?? "",
            "scnt": self.tfaScnt ?? ""
        ])
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body, options: [])
            req.httpBody = bodyData
            
            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                guard let _ = response, let data = data, error == nil else {
                    completionHandler(false, error)
                    return
                }
                
                let retStr = String(data: data, encoding: .utf8) ?? ""
                
                if retStr.isEmpty {
                    completionHandler(false, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                if retStr.contains("sectionErrorKeys")
                || retStr.contains("validationErrors")
                || retStr.contains("serviceErrors")
                || retStr.contains("sectionInfoKeys")
                || retStr.contains("sectionWarningKeys") {
                    // found an error
                    completionHandler(false, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                completionHandler(true, nil)
            }
            task.resume()
        } catch let jsonError {
            completionHandler(false, jsonError)
        }
    }
    
    public func finish2FAWith(code: String, phoneID: Int?, completionHandler: @escaping ((_ loggedIn: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)) {
        let url: URL!
        let body: [String: Any]!
        
        if phoneID == nil {
            url = URL(string: "https://idmsa.apple.com/appleauth/auth/verify/trusteddevice/securitycode")!
            body = [
                "securityCode": [
                    "code": code
                ]
            ]
        } else {
            //was phone code
            url = URL(string: "https://idmsa.apple.com/appleauth/auth/verify/phone/securitycode")!
            body = [
                "securityCode": [
                    "code": code
                ],
                "phoneNumber": [
                    "id": phoneID!
                ],
                "mode": "sms"
            ]
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req = self.updateHeadersFor(request: req, additionalFields: [
            "X-Apple-Id-Session-Id": self.tfaAppleIDSessionID ?? "",
            "scnt": self.tfaScnt ?? ""
        ])
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body ?? [String: Any](), options: [])
            
            req.httpBody = bodyData
            
            let task = URLSession.shared.dataTask(with: req, completionHandler: { (data, response, error) in
                guard let _ = response, let data = data, error == nil else {
                    completionHandler(false, nil, error)
                    return
                }
                
                let retStr = String(data: data, encoding: .utf8) ?? ""
                
                if retStr.contains("sectionErrorKeys")
                || retStr.contains("validationErrors")
                || retStr.contains("serviceErrors")
                || retStr.contains("sectionInfoKeys")
                || retStr.contains("sectionWarningKeys") {
                    // found an error
                    completionHandler(false, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                var req = URLRequest(url: URL(string: "https://idmsa.apple.com/appleauth/auth/2sv/trust")!)
                req.httpMethod = "GET"
                req = self.updateHeadersFor(request: req, additionalFields: [
                    "X-Apple-Id-Session-Id": self.tfaAppleIDSessionID ?? "",
                    "scnt": self.tfaScnt ?? ""
                ])
                
                let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                    guard let _ = response, let _ = data, error == nil else {
                        completionHandler(false, nil, error)
                        return
                    }
                    
                    self.loadSessionDataAfterLoginWith { (info, error) in
                        if info == nil || error != nil {
                            completionHandler(false, nil, error)
                            return
                        }
                        
                        //don't need them anymore from this point on
                        self.tfaAppleIDSessionID = nil
                        self.tfaScnt = nil
                        
                        completionHandler(true, info, nil)
                    }
                }
                task.resume()
            })
            task.resume()
        } catch let jsonError {
            completionHandler(false, nil, jsonError)
        }
    }
    
    func checkLoginWith(completionHandler: @escaping ((_ loggedIn: Bool, _ teams: [ASCTeam]?, _ currentTeamID: Int?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn || self.currentTeamID == nil || self.personID == nil {
            completionHandler(false, nil, nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.malformedRequest.rawValue, userInfo: nil))
        }
        
        self.sessionDataWith { (sessionDict, error) in
            completionHandler(sessionDict != nil && error == nil, self.cachedTeams, self.currentTeamID, error)
        }
    }
    
    // MARK: - App Retrieval
    
    public func getApps() -> [ASCApp]? {
        return self.currentTeam?.apps
    }
    
    func appsForTeamWith(providerID: Int, completionHandler: @escaping ((_ apps: [ASCApp]?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        if providerID == self.currentTeamID {
            self.appsForCurrentTeamWith(completionHandler: completionHandler)
            return
        }
        
        self.switchToTeamWith(teamID: providerID) { (sessionInfo, error) in
            if error != nil {
                completionHandler(nil, error)
            }
            
            self.appsForCurrentTeamWith(completionHandler: completionHandler)
        }
    }
    
    // MARK: - Promo Code Info and Creation
    
    public func promoCodeInfoForAppWith(appID: Int, completionHandler: @escaping ((_ info: ASCAppPromoCodesInfo?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        if appID == 0 {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.malformedRequest.rawValue, userInfo: nil))
            return
        }
        
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appID)/promocodes/versions")!)
        req.httpShouldHandleCookies = true
        req.httpMethod = "GET"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let dataDict = dict["data"] as? [String: Any],
                    let versions = dataDict["versions"] as? [[String: Any]],
                    let chosenDict = versions.first,
                    let version = chosenDict["version"] as? String,
                    let versionId = chosenDict["id"] as? Int,
                    let contractFilename = chosenDict["contractFileName"] as? String,
                    let maximumNumberOfCodes = chosenDict["maximumNumberOfCodes"] as? Int,
                    let numberOfCodes = chosenDict["numberOfCodes"] as? Int else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                let codesLeft = maximumNumberOfCodes - numberOfCodes
                
                let info = ASCAppPromoCodesInfo(
                    version: version,
                    versionId: versionId,
                    contractFilename: contractFilename,
                    codesLeft: codesLeft
                )
                
                completionHandler(info, nil)
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
    
    public func requestPromoCodesForAppWith(appID: Int,
                                     versionID: Int,
                                     quantity: Int,
                                     contractFilename: String,
                                     completionHandler: @escaping ((_ promoCodes: [ASCAppPromoCode]?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        if appID == 0 || quantity == 0 || contractFilename.isEmpty {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.malformedRequest.rawValue, userInfo: nil))
            return
        }
        
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appID)/promocodes/versions/")!)
        req.httpMethod = "POST"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        req.httpShouldHandleCookies = true
        
        let jsonArray: [[String: Any]] = [
            [
                "numberOfCodes": quantity,
                "agreedToContract": true,
                "versionId": versionID
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            req.httpBody = jsonData
            
            let creationRequestDate = Date(timeIntervalSinceNow: -1)
            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                guard let _ = response, let data = data, error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                do {
                    guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let dataDict = dict["data"] as? [String: Any],
                        let successfulArray = dataDict["successful"] as? [Any],
                        successfulArray.count > 0 else {
                        completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                        return
                    }
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        // promo code creation apparently takes a couple of seconds on Apple's servers, so it also takes a little while until they show up in the promo code history
                        // to minimize traffic, we wait 5 seconds after the promo code creation, and then start our recursive polling for the newly created codes.
                        self.recursivelyLoadPromoCodeHistoryForAppWith(appID: appID, creationRequestDate: creationRequestDate, completionHandler: completionHandler)
                    }
                    
                } catch let jsonError {
                    completionHandler(nil, jsonError)
                }
            }
            task.resume()
        } catch let jsonError {
            completionHandler(nil, jsonError)
        }
    }
    
    // MARK: - IAPs and IAP promo codes
    
    public func iapsForAppWith(appId: Int, completionHandler: @escaping ((_ iaps: [ASCAppInternalPurchase]?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appId)/iaps")!)
        req.httpMethod = "GET"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        req.httpShouldHandleCookies = true
        
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                let json = try JSON(data: data)
                guard let data = json["data"].array else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                var iaps = [ASCAppInternalPurchase]()
                
                for inAppPurchaseJson in data {
                    let adamId = inAppPurchaseJson["adamId"].stringValue
                    let name = inAppPurchaseJson["referenceName"].stringValue
                    let maximumNumberOfCodes = inAppPurchaseJson["maximumNumberOfCodes"].intValue
                    let numberOfCodes = inAppPurchaseJson["numberOfCodes"].intValue
                    
                    iaps.append(ASCAppInternalPurchase(id: adamId, name: name, codesLeft: maximumNumberOfCodes - numberOfCodes))
                }
                
                completionHandler(iaps, nil)
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
    
    public func requestIapPromoCodesFor(iapID: Int,
                                        appID: Int,
                                     quantity: Int,
                                     completionHandler: @escaping ((_ promoCodes: [ASCIapPromoCode]?, _ error: Error?) -> Void)) {
        if !self.isLoggedIn {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        if iapID == 0 || appID == 0 || quantity == 0 {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.malformedRequest.rawValue, userInfo: nil))
            return
        }
        
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appID)/promocodes/iaps")!)
        req.httpMethod = "POST"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        req.httpShouldHandleCookies = true
        
        let jsonArray: [[String: Any]] = [
            [
                "numberOfCodes": quantity,
                "agreedToContract": true,
                "adamId": iapID
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            req.httpBody = jsonData
            
            let creationRequestDate = Date(timeIntervalSinceNow: -1)
            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                guard let _ = response, let data = data, error == nil else {
                    completionHandler(nil, error)
                    return
                }
                
                do {
                    guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                        let dataDict = dict["data"] as? [String: Any],
                        let successfulArray = dataDict["successful"] as? [Any],
                        successfulArray.count > 0 else {
                        completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                        return
                    }
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                        // promo code creation apparently takes a couple of seconds on Apple's servers, so it also takes a little while until they show up in the promo code history
                        // to minimize traffic, we wait 5 seconds after the promo code creation, and then start our recursive polling for the newly created codes.
                        self.recursivelyLoadIapPromoCodeHistoryForAppWith(appID: appID, creationRequestDate: creationRequestDate, completionHandler: completionHandler)
                    }
                    
                } catch let jsonError {
                    completionHandler(nil, jsonError)
                }
            }
            task.resume()
        } catch let jsonError {
            completionHandler(nil, jsonError)
        }
    }

    // MARK: - Helper Methods
    
    var isLoggedIn: Bool {
        return self.authServiceKey.count != 0 && self.personID != nil
    }

    func updateHeadersFor(request: URLRequest, additionalFields: [String: String]) -> URLRequest {
        var request = request
        
        if request.httpMethod == "POST" || request.httpMethod == "PUT" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        if !self.authServiceKey.isEmpty {
            request.setValue(self.authServiceKey, forHTTPHeaderField: "X-Apple-Widget-Key")
        }
        
        request.setValue("application/json, text/javascript", forHTTPHeaderField: "Accept")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("Tokens by Gikken", forHTTPHeaderField: "User-Agent")
        
        for (key, value) in additionalFields {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }

    func loadSessionDataAfterLoginWith(completionHandler: @escaping ((_ info: [String: Any]?, _ error: Error?) -> Void)) {
        sessionDataWith { (sessionDict, error) in
            guard let sessionDict = sessionDict, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            self.userSession = sessionDict
            
            let teamsArray = sessionDict["availableProviders"] as? [[String: Any]] ?? [[String: Any]]()
            
            var teams = [ASCTeam]()
            for teamDict in teamsArray {
                guard let name = teamDict["name"] as? String, let id = teamDict["providerId"] as? Int else {
                    continue
                }
                let newTeam = ASCTeam(name: name, providerId: id, apps: [])
                teams.append(newTeam)
            }
            
            teams.sort { (team1, team2) -> Bool in
                team1.name.compare(team2.name) == .orderedAscending
            }
            
            self.cachedTeams = teams
            
            self.currentTeamID = (sessionDict["provider"] as? [String: Any])?["providerId"] as? Int
            self.personID = (sessionDict["user"] as? [String: Any])?["prsId"] as? String
            
            if self.currentTeamID != nil {
                self.appsForTeamWith(providerID: self.currentTeamID!) { (apps, error) in
                    guard let apps = apps, error == nil else {
                        completionHandler(nil, error)
                        return
                    }
                    
                    var teamIndex = 0
                    for team in self.cachedTeams {
                        var team = team
                        if team.providerId == self.currentTeamID {
                            team.apps = apps
                            self.cachedTeams[teamIndex] = team
                            break
                        }
                        teamIndex += 1
                    }
                    
                    completionHandler([
                        "teams": self.cachedTeams,
                        "teamID": self.currentTeamID ?? -1
                    ], nil)
                }
            } else {
                completionHandler(nil, error)
            }
        }
    }
    
    func sessionDataWith(completionHandler: @escaping ((_ sessionDict: [String: Any]?, _ error: Error?) -> Void)) {
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/olympus/v1/session")!)
        req.httpShouldHandleCookies = true
        
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                guard let sessionDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                completionHandler(sessionDict, nil)
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
    
    public func getTeams() -> [ASCTeam]? {
        return self.cachedTeams
    }
    
    public func switchToTeamWith(teamID: Int, completionHandler: @escaping ((_ sessionDict: [String: Any]?, _ error: Error?) -> Void)) {
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/olympus/v1/session")!)
        req.httpShouldHandleCookies = true
        req.httpMethod = "POST"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        
        guard let jsonDict = self.userSession else {
            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS, code: GKASCAPIErrorCode.codeNotLoggedIn.rawValue, userInfo: nil))
            return
        }
        
        do {
            let sessionData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            
            var sessionJson = try JSON(data: sessionData)
            sessionJson["provider"]["providerId"].int = teamID
            
            req.httpBody = try sessionJson.rawData()
            
            let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
                guard let _ = response, let _ = data, error == nil else {
                    completionHandler(nil, error)
                    return
                }
                self.loadSessionDataAfterLoginWith(completionHandler: completionHandler)
            }
            task.resume()
        } catch let jsonError {
            completionHandler(nil, jsonError)
        }
    }
    
    func appsForCurrentTeamWith(completionHandler: @escaping ((_ apps: [ASCApp]?, _ error: Error?) -> Void)) {
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/manageyourapps/summary/v2")!)
        req.httpShouldHandleCookies = true
        req.httpMethod = "GET"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let appIDs = (dict["data"] as? [String: Any])?["summaries"] as? [[String: Any]] else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                var apps = [ASCApp]()
                for dict in appIDs {
                    // TODO: This is unreadable shit, need a better way to access all this. Embed SwiftyJSON permanently?
                    if ((dict["versionSets"] as? [[String: Any]])?.first)?["type"] as? String == "BUNDLE"
                        || ((dict["buildVersionSets"] as? [[String: Any]])?.first)?["type"] as? String == "BUNDLE" {
                        continue
                    }
                    
                    guard let versionSets = dict["versionSets"] as? [[String: Any]] else {
                        completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                        return
                    }
                    
                    var platform = ""
                    for version in versionSets {
                        platform = version["platformString"] as? String ?? "" //'osx' or 'ios' or 'appletvos'
                        if !platform.isEmpty {
                            break
                        }
                    }
                    
                    if platform.isEmpty {
                        guard let versionSets = dict["buildVersionSets"] as? [[String: Any]] else {
                            completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                            return
                        }
                        
                        for version in versionSets {
                            platform = version["platformString"] as? String ?? "" //'osx' or 'ios' or 'appletvos'
                            if !platform.isEmpty {
                                break
                            }
                        }
                    }
                    
                    // assuming platform is not empty now
                    
                    let adamId = dict["adamId"] as? String ?? ""
                    let sku = dict["vendorId"] as? String ?? ""
                    let name = dict["name"] as? String ?? ""
                    let iconUrl = dict["iconUrl"] as? String ?? ""
                    
                    // TODO: Looks like the app is missing a name at this point
                    
                    if !adamId.isEmpty {
                        apps.append(ASCApp(id: adamId, sku: sku, platform: platform, iconUrl: iconUrl, name: name))
                    }
                }
                
                apps.sort { (app1, app2) -> Bool in
                    return app1.id > app2.id
                }
                
                var teamIndex = 0
                for team in self.cachedTeams {
                    var team = team
                    if team.providerId == self.currentTeamID {
                        team.apps = apps
                        self.cachedTeams[teamIndex] = team
                        break
                    }
                    teamIndex += 1
                }
                
                completionHandler(apps, nil)
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
    
    func recursivelyLoadPromoCodeHistoryForAppWith(appID: Int, creationRequestDate: Date, completionHandler: @escaping ((_ promoCodes: [ASCAppPromoCode]?, _ error: Error?) -> Void)) {
        let lastRequestDate = Date()
        self.promoCodeHistoryForAppWith(appID: appID) { (historyDicts, error) in
            guard let historyDicts = historyDicts,
                historyDicts.count > 0,
                error == nil else {
                    completionHandler(nil, error)
                    return
            }
            
            var finalCodes = [ASCAppPromoCode]()
            for codeDict in historyDicts {
                guard let codes = codeDict["codes"] as? [String],
                    codes.count > 0,
                    let creationDateNanoseconds = codeDict["effectiveDate"] as? Int,
                    let expDateNanoseconds = codeDict["expirationDate"] as? Int else {
                        continue
                }
                
                let creationDateTimeInterval = TimeInterval(creationDateNanoseconds) / 1000
                let creationDate = Date(timeIntervalSince1970: creationDateTimeInterval)
                if creationRequestDate > creationDate {
                    // these promo codes were created before we requested them here - ignore.
                    continue
                }
                
                let expDateTimeInterval = TimeInterval(expDateNanoseconds) / 1000
                let expDate = Date(timeIntervalSince1970: expDateTimeInterval)
                
                for code in codes {
                    let code = code
                    let requestId = codeDict["id"] as? String ?? ""
                    let platform = (codeDict["version"] as? [String: Any])?["platform"] as? String ?? "" //osx, ios or appletvos
                    let version = (codeDict["version"] as? [String: Any])?["version"] as? String ?? ""
                    
                    finalCodes.append(ASCAppPromoCode(code: code, creationDate: creationDate, expirationDate: expDate, requestId: requestId, platform: platform, version: version))
                }
            }
            
            if finalCodes.count == 0 {
                // as to not the "flood" the server with too many requests, at least 'minTimeToHavePassed' seconds have to have passed since the last request. maybe raise that at some point.
                let minTimeToHavePassed = 10.0
                var timeLeft = minTimeToHavePassed - Date().timeIntervalSince(lastRequestDate)
                if timeLeft <= 0 {
                    timeLeft = 0.01
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + timeLeft) {
                    self.recursivelyLoadPromoCodeHistoryForAppWith(appID: appID, creationRequestDate: creationRequestDate, completionHandler: completionHandler)
                }
                return
            }
            
            completionHandler(finalCodes, nil)
        }
    }
    
    func recursivelyLoadIapPromoCodeHistoryForAppWith(appID: Int, creationRequestDate: Date, completionHandler: @escaping ((_ promoCodes: [ASCIapPromoCode]?, _ error: Error?) -> Void)) {
        let lastRequestDate = Date()
        self.iapPromoCodeHistoryForAppWith(appID: appID) { (historyDicts, error) in
            guard let historyDicts = historyDicts,
                historyDicts.count > 0,
                error == nil else {
                    completionHandler(nil, error)
                    return
            }
            
            var finalCodes = [ASCIapPromoCode]()
            for codeDict in historyDicts {
                guard let codes = codeDict["codes"] as? [String],
                    codes.count > 0,
                    let creationDateNanoseconds = codeDict["effectiveDate"] as? Int,
                    let expDateNanoseconds = codeDict["expirationDate"] as? Int else {
                        continue
                }
                
                let creationDateTimeInterval = TimeInterval(creationDateNanoseconds) / 1000
                let creationDate = Date(timeIntervalSince1970: creationDateTimeInterval)
                if creationRequestDate > creationDate {
                    // these promo codes were created before we requested them here - ignore.
                    continue
                }
                
                let expDateTimeInterval = TimeInterval(expDateNanoseconds) / 1000
                let expDate = Date(timeIntervalSince1970: expDateTimeInterval)
                
                for code in codes {
                    let code = code
                    let requestId = codeDict["id"] as? String ?? ""
                    
                    finalCodes.append(ASCIapPromoCode(code: code, creationDate: creationDate, expirationDate: expDate, requestId: requestId))
                }
            }
            
            if finalCodes.count == 0 {
                // as to not the "flood" the server with too many requests, at least 'minTimeToHavePassed' seconds have to have passed since the last request. maybe raise that at some point.
                let minTimeToHavePassed = 10.0
                var timeLeft = minTimeToHavePassed - Date().timeIntervalSince(lastRequestDate)
                if timeLeft <= 0 {
                    timeLeft = 0.01
                }
                
                DispatchQueue.global().asyncAfter(deadline: .now() + timeLeft) {
                    self.recursivelyLoadIapPromoCodeHistoryForAppWith(appID: appID, creationRequestDate: creationRequestDate, completionHandler: completionHandler)
                }
                return
            }
            
            completionHandler(finalCodes, nil)
        }
    }
    
    func promoCodeHistoryForAppWith(appID: Int, completionHandler: @escaping ((_ historyDicts: [[String: Any]]?, _ error: Error?) -> Void)) {
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appID)/promocodes/history")!)
        req.httpMethod = "GET"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        req.httpShouldHandleCookies = true
        
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let dataDict = dict["data"] as? [String: Any],
                    let codeDicts = dataDict["requests"] as? [[String: Any]] else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                completionHandler(codeDicts, nil)
                
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
    
    func iapPromoCodeHistoryForAppWith(appID: Int, completionHandler: @escaping ((_ historyDicts: [[String: Any]]?, _ error: Error?) -> Void)) {
        var req = URLRequest(url: URL(string: "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/\(appID)/promocodes/iap/history")!)
        req.httpMethod = "GET"
        req = self.updateHeadersFor(request: req, additionalFields: [:])
        req.httpShouldHandleCookies = true
        
        let task = URLSession.shared.dataTask(with: req) { (data, response, error) in
            guard let _ = response, let data = data, error == nil else {
                completionHandler(nil, error)
                return
            }
            
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let dataDict = dict["data"] as? [String: Any],
                    let codeDicts = dataDict["promoCodeRequests"] as? [[String: Any]] else {
                    completionHandler(nil, NSError(domain: GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES, code: GKASCAPIErrorCode.unexpectedReply.rawValue, userInfo: nil))
                    return
                }
                
                completionHandler(codeDicts, nil)
                
            } catch let jsonError {
                completionHandler(nil, jsonError)
            }
        }
        task.resume()
    }
}
