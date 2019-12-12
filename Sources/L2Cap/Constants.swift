//
//  Constants.swift
//  
//
//  Created by Paul Wilkinson on 13/12/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//


import Foundation
import CoreBluetooth

struct Constants {
    static let serviceID = CBUUID(string:"12E61727-B41A-436F-B64D-4777B35F2294")
    static let PSMID = CBUUID(string:CBUUIDL2CAPPSMCharacteristicString)
}
