//
//  File.swift
//  
//
//  Created by Paul Wilkinson on 13/12/19.
//

import Foundation
import CoreBluetooth


public typealias L2CapDiscoveredPeripheralCallback = (CBPeripheral)->Void
public typealias L2CapStateCallback = (CBManagerState)->Void
public typealias L2CapConnectionCallback = (L2CapConnection)->Void
public typealias L2CapDisconnectionCallback = (L2CapConnection,Error?)->Void
public typealias L2CapReceiveDataCallback = (L2CapConnection,Data)->Void
public typealias L2CapSentDataCallback = (L2CapConnection, Int)->Void

public protocol L2CapConnection {
    
    var receiveCallback:L2CapReceiveDataCallback? {get set}
    var sentDataCallback: L2CapSentDataCallback? {get set}
       
    func send(data: Data) -> Void
    
}
