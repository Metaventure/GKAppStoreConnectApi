//
//  main.swift
//  GKAppStoreConnectApiExample
//
//  Created by Andrew Liakh on 29.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation
import GKAppStoreConnectApi

print("Hello, World!")

let dispatchGroup = DispatchGroup()

dispatchGroup.enter()
GKAppStoreConnectApi.shared.loginWith(username: tetUsername, password: testPassword) { (loggedIn, needs2FA, info, error) in
    if error != nil {
        print(error!)
    }
    
    dispatchGroup.leave()
    dispatchGroup.notify(queue: DispatchQueue.main) {
        exit(EXIT_SUCCESS)
    }
}

dispatchMain()
