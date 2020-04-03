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
}

public struct ASCUser {
    public var email: String
    public var personId: String
    public var currentTeamId: String
    public var teams: [ASCTeam]
}

public struct ASCTeam {
    public var name: String
    public var providerId: Int
    public var apps: [ASCApp]
}

public struct ASCAppPromoCodesInfo {
    public var version: String
    public var versionId: Int
    public var contractFilename: String
    public var codesLeft: Int
}

public struct ASCAppInternalPurchase {
    public var id: String
    public var name: String
    public var codesLeft: Int
}

public struct ASCAppPromoCode {
    public var code: String
    public var creationDate: Date
    public var expirationDate: Date
    public var requestId: String
    public var platform: String
    public var version: String
}

public struct ASCIapPromoCode {
    public var code: String
    public var creationDate: Date
    public var expirationDate: Date
    public var requestId: String
}

public struct ASCInAppPurchasePromoCode {
    public var code: String
    public var creationDate: Int
    public var expirationDate: Int
    public var requestId: String
}

let GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN = "co.gikken.PromoCodes.AppStoreConnectLogin"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS = "co.gikken.PromoCodes.AppStoreConnectApps"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES = "co.gikken.PromoCodes.AppStoreConnectPromoCodes"
