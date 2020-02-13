//
//  main.swift
//  GKAppStoreConnectApiExample
//
//  Created by Andrew Liakh on 29.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation
import GKAppStoreConnectApi

var proceed = true

while(true) {
    if proceed {
        print("supported commands: login, exit")
        let command = readLine()
        switch command {
        case "login":
            print("username:")
            let username = readLine() ?? ""
            print("password:")
            let password = readLine() ?? ""
            proceed = false
            GKAppStoreConnectApi.shared.loginWith(username: username, password: password) { (loggedIn, needs2FA, info, error) in
                if error != nil {
                    print(error!)
                }
                
                if loggedIn {
                    print("Logged in")
                    proceed = true
                } else if needs2FA {
                    print("2FA needed")
                    let didSendCode = info?["didSendCode"] as? Bool ?? false
                    let phoneNumber = (info?["resendInfo"] as? [String: Any])?["phoneNumber"] as? String
                    let usedTrustedDevices = info?["wasTrustedDeviceCode"] as? Bool ?? false
                    var phoneId = (info?["resendInfo"] as? [String: Any])?["phoneID"] as? Int
                    
                    if didSendCode && (usedTrustedDevices || phoneNumber == nil) {
                        print("Code was sent to your trusted devices")
                    } else if didSendCode && phoneNumber != nil {
                        print("Code was sent to \(phoneNumber!)")
                    }
                    
                    print("Want to use another option? y/n")
                    let another = readLine() == "y"
                    
                    if !didSendCode || another {
                        print("Please select a phone number:")
                        let phoneNumbers = (info?["phoneNumbers"] as? [[String: Any]]) ?? [[String: Any]]()
                        for phoneNumber in phoneNumbers {
                            print("\(phoneNumber["id"] as? Int ?? -1): \(phoneNumber["numberWithDialCode"] as? String ?? "")")
                        }
                        let newPhoneId = readLine() ?? ""
                        let intPhoneId = Int(newPhoneId) ?? -1
                        phoneId = intPhoneId
                        if intPhoneId != -1 {
                            GKAppStoreConnectApi.shared.resend2FACodeWith(phoneID: intPhoneId) { (codeSent, error) in
                                
                            }
                        } else {
                            print("error")
                        }
                    } else if !loggedIn && !needs2FA {
                        proceed = true
                        return
                    }
                    
                    print("Enter code:")
                    let code = readLine() ?? ""
                    if !code.isEmpty {
                        GKAppStoreConnectApi.shared.finish2FAWith(code: code, phoneID: phoneId) { (loggedIn, info, error) in
                            if loggedIn {
                                print("Successfully logged in")
                            } else {
                                print("Log in failed. Error: \(error?.localizedDescription ?? "")")
                            }
                            proceed = true
                        }
                    } else {
                        print("error")
                        proceed = true
                    }
                    
                }
            }
            break
        case "exit":
            exit(EXIT_SUCCESS)
        default:
            break
        }
    }
    usleep(100000)
}
