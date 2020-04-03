//
//  Errors.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew on 03.04.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

enum GKASCAPIErrorCode: Int {
    case malformedRequest = 1
    case serviceKeyMissing = 2
    case unexpectedReply = 3
    case securityCodeLocked = 4
    case tooManyCodesSent = 5
    case tooManyCodesValidated = 6
    case codeNotLoggedIn = 7
    case badJson = 8
    case teamNotSelected = 9
    case badTwoFactorCode = 10
    case badCredentials = 11
}

struct MalformedRequestError: LocalizedError {
    var title: String? = "User Cancelled"
    var code = GKASCAPIErrorCode.malformedRequest
    var errorDescription: String?
    var failureReason: String?
    var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct ServiceKeyMissingError: LocalizedError {
    var title: String? = "Service key missing"
    var code = GKASCAPIErrorCode.serviceKeyMissing
    var errorDescription: String?
    var failureReason: String?
    var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct UnexpectedReplyError: LocalizedError {
    var title: String? = "Unexpected reply"
    var code = GKASCAPIErrorCode.unexpectedReply
    var errorDescription: String?
    var failureReason: String?
    var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct SecurityCodeLockedError: LocalizedError {
    var title: String? = "Security code locked"
    var code = GKASCAPIErrorCode.securityCodeLocked
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct TooManyCodesSentError: LocalizedError {
    var title: String? = "Too many codes sent"
    var code = GKASCAPIErrorCode.tooManyCodesSent
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct TooManyCodesValidatedError: LocalizedError {
    var title: String? = "Too many codes validated"
    var code = GKASCAPIErrorCode.tooManyCodesValidated
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct NotLoggedInError: LocalizedError {
    var title: String? = "Not logged in"
    var code = GKASCAPIErrorCode.codeNotLoggedIn
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct BadJsonError: LocalizedError {
    var title: String? = "Bad JSON"
    var code = GKASCAPIErrorCode.badJson
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct TeamNotSelected: LocalizedError {
    var title: String? = "Team not selected"
    var code = GKASCAPIErrorCode.teamNotSelected
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct BadTwoFactorCodeError: LocalizedError {
    var title: String? = "Bad 2FA code"
    var code = GKASCAPIErrorCode.badTwoFactorCode
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

struct BadCredentialsError: LocalizedError {
    var title: String? = "Wrong username or password"
    var code = GKASCAPIErrorCode.badCredentials
    var errorDescription: String? = nil
    var failureReason: String? = nil
    var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}
