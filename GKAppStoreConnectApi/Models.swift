//
//  Models.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew Liakh on 28.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

public struct ASCApp {
    public var id: String
    public var sku: String
    public var platform: String
    public var iconUrl: String
    public var name: String
    
    public init(id: String, sku: String, platform: String, iconUrl: String, name: String) {
        self.id = id
        self.sku = sku
        self.platform = platform
        self.iconUrl = iconUrl
        self.name = name
    }
}

public struct ASCUser {
    public var email: String
    public var personId: String
    public var currentTeamId: String
    public var teams: [ASCTeam]
    
    public init(email: String, personId: String, currentTeamId: String, teams: [ASCTeam]) {
        self.email = email
        self.personId = personId
        self.currentTeamId = currentTeamId
        self.teams = teams
    }
}

public struct ASCTeam {
    public var name: String
    public var providerId: Int
    public var apps: [ASCApp]
    
    public init(name: String, providerId: Int, apps: [ASCApp]) {
        self.name = name
        self.providerId = providerId
        self.apps = apps
    }
}

public struct ASCAppPromoCodesInfo {
    public var version: String
    public var versionId: Int
    public var contractFilename: String
    public var codesLeft: Int
    
    public init(version: String, versionId: Int, contractFilename: String, codesLeft: Int) {
        self.version = version
        self.versionId = versionId
        self.contractFilename = contractFilename
        self.codesLeft = codesLeft
    }
}

public struct ASCAppInternalPurchase {
    public var id: String
    public var name: String
    public var codesLeft: Int
    
    public init(id: String, name: String, codesLeft: Int) {
        self.id = id
        self.name = name
        self.codesLeft = codesLeft
    }
}

public struct ASCPromoCode {
    public var code: String
    public var creationDate: Date
    public var expirationDate: Date
    public var requestId: String
    public var platform: String? = nil
    public var version: String? = nil
    
    public init(code: String, creationDate: Date, expirationDate: Date, requestId: String, platform: String? = nil, version: String? = nil) {
        self.code = code
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.requestId = requestId
        self.platform = platform
        self.version = version
    }
}

public struct ASCInAppPurchasePromoCode {
    public var code: String
    public var creationDate: Int
    public var expirationDate: Int
    public var requestId: String
    
    public init(code: String, creationDate: Int, expirationDate: Int, requestId: String) {
        self.code = code
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.requestId = requestId
    }
}

let GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN = "co.gikken.PromoCodes.AppStoreConnectLogin"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS = "co.gikken.PromoCodes.AppStoreConnectApps"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES = "co.gikken.PromoCodes.AppStoreConnectPromoCodes"
