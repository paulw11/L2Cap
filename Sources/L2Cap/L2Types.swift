//
//  File.swift
//  
//
//  Created by Paul Wilkinson on 13/12/19.
//

import Foundation
import CoreBluetooth


public typealias DiscoveredPeripheralCallback = (CBPeripheral)->Void
public typealias StateCallback = (CBManagerState)->Void
public typealias L2CapConnectionCallback = (L2CapConnection)->Void
public typealias L2CapReceiveData = (L2CapConnection,Data)->Void

public protocol L2CapConnection {
    
    var receiveCallback:L2CapReceiveData? {get set}
       
    func send(data: Data) -> Void
    
}
