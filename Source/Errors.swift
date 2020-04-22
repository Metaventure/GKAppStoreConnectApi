//  Errors.swift
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

public enum GKASCAPIErrorCode: Int {
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

public struct MalformedRequestError: LocalizedError {
    public var title: String? = "User Cancelled"
    public var code = GKASCAPIErrorCode.malformedRequest
    public var errorDescription: String?
    public var failureReason: String?
    public var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct ServiceKeyMissingError: LocalizedError {
    public var title: String? = "Service key missing"
    public var code = GKASCAPIErrorCode.serviceKeyMissing
    public var errorDescription: String?
    public var failureReason: String?
    public var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct UnexpectedReplyError: LocalizedError {
    public var title: String? = "Unexpected reply"
    public var code = GKASCAPIErrorCode.unexpectedReply
    public var errorDescription: String?
    public var failureReason: String?
    public var domain: String?
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct SecurityCodeLockedError: LocalizedError {
    public var title: String? = "Security code locked"
    public var code = GKASCAPIErrorCode.securityCodeLocked
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct TooManyCodesSentError: LocalizedError {
    public var title: String? = "Too many codes sent"
    public var code = GKASCAPIErrorCode.tooManyCodesSent
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct TooManyCodesValidatedError: LocalizedError {
    public var title: String? = "Too many codes validated"
    public var code = GKASCAPIErrorCode.tooManyCodesValidated
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct NotLoggedInError: LocalizedError {
    public var title: String? = "Not logged in"
    public var code = GKASCAPIErrorCode.codeNotLoggedIn
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct BadJsonError: LocalizedError {
    public var title: String? = "Bad JSON"
    public var code = GKASCAPIErrorCode.badJson
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct TeamNotSelected: LocalizedError {
    public var title: String? = "Team not selected"
    public var code = GKASCAPIErrorCode.teamNotSelected
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct BadTwoFactorCodeError: LocalizedError {
    public var title: String? = "Bad 2FA code"
    public var code = GKASCAPIErrorCode.badTwoFactorCode
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}

public struct BadCredentialsError: LocalizedError {
    public var title: String? = "Wrong username or password"
    public var code = GKASCAPIErrorCode.badCredentials
    public var errorDescription: String? = nil
    public var failureReason: String? = nil
    public var domain: String? = nil
    
    init (domain: String? = nil) {
        self.domain = domain
    }
}
