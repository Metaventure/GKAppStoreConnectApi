//  Models.swift
//
//  Copyright (c) 2020 Gikken UG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
