//  L2CapPeripheral.swift
//  L2Cap
//
//  Created by Paul Wilkinson on 13/12/19.
//  Copyright © 2019 Paul Wilkinson. All rights reserved.
//


import CoreBluetooth

public class L2CapPeripheral: NSObject {
    
    public var publish: Bool = false {
        didSet {
            self.publishService()
        }
    }
    
    private var service: CBMutableService
    private var characteristic: CBMutableCharacteristic
    private var peripheralManager: CBPeripheralManager!
    private var subscribedCentrals = [CBCharacteristic:[CBCentral]]()
    private var channel: CBL2CAPChannel?
    private var channelPSM: UInt16?
    private var managerQueue = DispatchQueue.global(qos: .utility)
    private var connectionHandler: L2CapConnectionCallback
    
    init(connectionHandler:  @escaping L2CapConnectionCallback) {
        
        self.service = CBMutableService(type: Constants.serviceID, primary: true)
        self.characteristic = CBMutableCharacteristic(type: Constants.PSMID, properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate], value: nil, permissions: [CBAttributePermissions.readable] )
        self.connectionHandler = connectionHandler
        super.init()
        self.service.characteristics = [self.characteristic]
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: managerQueue)
    }
    
    private func publishService() {
        guard peripheralManager.state == .poweredOn, publish else {
            self.unpublishService()
            return
        }
        
        self.peripheralManager.add(self.service)
        self.peripheralManager.publishL2CAPChannel(withEncryption: false)
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [Constants.serviceID]])
        
    }
    
    private func unpublishService() {
        self.peripheralManager.stopAdvertising()
    }
}

extension L2CapPeripheral: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            self.publishService()
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        var centrals = self.subscribedCentrals[characteristic, default: [CBCentral]()]
        centrals.append(central)
        self.subscribedCentrals[characteristic]  = centrals
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didPublishL2CAPChannel PSM: CBL2CAPPSM, error: Error?) {
        if let error = error {
            print("Error publishing channel: \(error.localizedDescription)")
            return
        }
        print("Published channel \(PSM)")
        
        self.channelPSM = PSM
        
        if let data = "\(PSM)".data(using: .utf8) {
            
            self.characteristic.value = data
            
            self.peripheralManager.updateValue(data, for: self.characteristic, onSubscribedCentrals: self.subscribedCentrals[self.characteristic])
        }
        
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if let psm = self.channelPSM, let data = "\(psm)".data(using: .utf8) {
            request.value = characteristic.value
            print("Respond \(data)")
            self.peripheralManager.respond(to: request, withResult: .success)
        } else {
            self.peripheralManager.respond(to: request, withResult: .unlikelyError)
        }
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didOpen channel: CBL2CAPChannel?, error: Error?) {
        
        if let error = error {
            print("Error opening channel: \(error.localizedDescription)")
           return
        }
        self.channel = channel
        if let channel = self.channel {
            let connection = L2CapPeripheralConnection(channel: channel)
            self.connectionHandler(connection)
        }
    }
    
}


