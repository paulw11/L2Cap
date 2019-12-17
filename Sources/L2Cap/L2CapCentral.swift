//  L2CapPeripheral.swift
//  L2Cap
//
//  Created by Paul Wilkinson on 13/12/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//

import Foundation
import CoreBluetooth

public class L2CapCentral: NSObject {

    private var managerQueue = DispatchQueue.global(qos: .utility)
    
    public var discoveredPeripheralCallback: DiscoveredPeripheralCallback?
    
    public var scan: Bool = false {
        didSet {
            self.startStopScanning()
        }
    }
      
    private var central:CBCentralManager!
    
    private var pendingConnections = Dictionary<String,L2CapConnection>()
  
    
    override public init() {
        super.init()
         self.central = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func startStopScanning() {
        guard self.central.state == .poweredOn else {
            return
        }
        if self.scan {
            self.central.scanForPeripherals(withServices: [Constants.serviceID], options: nil)
        } else {
            self.central.stopScan()
        }
    }
    
    public func connect(peripheral: CBPeripheral, connectionHandler:  @escaping L2CapConnectionCallback)  {
        self.central.connect(peripheral)
        let l2Connection = L2CapCentralConnection(peripheral: peripheral, connectionCallback: connectionHandler)
        self.pendingConnections[peripheral.identifier.uuidString] = l2Connection
        
    }
}

extension L2CapCentral: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.startStopScanning()
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.discoveredPeripheralCallback?(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let _ = self.pendingConnections[peripheral.identifier.uuidString] else {
            return
        }
        peripheral.discoverServices([Constants.serviceID])
    }
}



