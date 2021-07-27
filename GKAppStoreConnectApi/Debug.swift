//
//  Debug.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew on 08.12.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

func debugLog(_ object: Any?) {
    let string = "\(object ?? "nil")"
    
    // NSLog has a stupid limit on length, but print doesn't appear in device console. Fucking great.
    if string.count > 1024 {
        print(string)
    } else {
        NSLog(string)
    }
}
