//
//  Models.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew Liakh on 28.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

struct ASCApp {
    var id: String
    var sku: String
    var platform: String
}

struct ASCUser {
    var personId: String
    var currentTeamId: String
    var teams: [ASCTeam]
}

struct ASCTeam {
    var name: String
    var providerId: Int
    var apps: [ASCApp]
}

struct ASCAppPromoCodesInfo {
    var version: String
    var versionId: String
    var contractFilename: String
    var codesLeft: Int
}

struct ASCAppPromoCode {
    var code: String
    var creationDate: Date
    var expirationDate: Date
    var requestId: String
    var platform: String
    var version: String
}

struct ASCInAppPurchasePromoCode {
    var code: String
    var creationDate: Int
    var expirationDate: Int
    var requestId: String
}

enum GKASCAPIErrorCode: Int {
    case malformedRequest = 1
    case serviceKeyMissing = 2
    case unexpectedReply = 3
    case securityCodeLocked = 4
    case tooManyCodesSent = 5
    case tooManyCodesValidated = 6
    case codeNotLoggedIn = 7
    case badJson = 8
}

let GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN = "co.gikken.PromoCodes.AppStoreConnectLogin"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS = "co.gikken.PromoCodes.AppStoreConnectApps"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES = "co.gikken.PromoCodes.AppStoreConnectPromoCodes"
