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
    
    public var publishChannel: Bool = false {
        didSet {
            self.publishL2CAPChannel()
        }
    }
    
    private var service: CBMutableService?
    private var characteristic: CBMutableCharacteristic?
    private var peripheralManager: CBPeripheralManager
    private var subscribedCentrals = [CBCharacteristic:[CBCentral]]()
    private var channelPSM: UInt16? {
        didSet {
            self.updatePSM()
        }
    }
    private var managerQueue = DispatchQueue.global(qos: .utility)
    private var connectionHandler: L2CapConnectionCallback
    private var connection: L2CapConnection?
    
    public override init() {
        fatalError("Call init(connectionHandler:)")
    }
    
    public init(connectionHandler:  @escaping L2CapConnectionCallback) {
        
        
        self.connectionHandler = connectionHandler
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: managerQueue)
        super.init()
        self.peripheralManager.delegate = self
    }
    
    private func publishService() {
        guard peripheralManager.state == .poweredOn, publish else {
            self.unpublishService()
            return
        }
        self.service = CBMutableService(type: Constants.psmServiceID, primary: true)
        self.characteristic = CBMutableCharacteristic(type: Constants.PSMID, properties: [ CBCharacteristicProperties.read, CBCharacteristicProperties.indicate], value: nil, permissions: [CBAttributePermissions.readable] )
        self.service?.characteristics = [self.characteristic!]
        self.peripheralManager.add(self.service!)
       
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [Constants.psmServiceID]])
        self.publishChannel = true
    }
    
    private func publishL2CAPChannel() {
        guard self.channelPSM == nil, publishChannel else {
            self.unpublishL2CAPChannel()
            return
        }
        self.peripheralManager.publishL2CAPChannel(withEncryption: false)
    }
    
    private func unpublishL2CAPChannel() {
        guard let psm = self.channelPSM, !publishChannel else {
            return
        }
        self.connection?.close()
        self.peripheralManager.unpublishL2CAPChannel(psm)
        self.channelPSM = nil
    }
    
    private func unpublishService() {
        self.publishChannel = false
        self.peripheralManager.stopAdvertising()
        self.peripheralManager.removeAllServices()
        self.subscribedCentrals.removeAll()
        self.characteristic = nil
        self.service = nil
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
        
       
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if let characteristic = self.characteristic {
            request.value = characteristic.value
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
        if let channel = channel {
            let connection = L2CapPeripheralConnection(channel: channel)
            self.connection = connection
            self.connectionHandler(connection)
        }
    }
    
    private func updatePSM() {
        
        self.characteristic?.value = self.channelPSM?.data
        
        let value = self.channelPSM?.data ?? Data()
        
        self.peripheralManager.updateValue(value, for: self.characteristic!, onSubscribedCentrals: self.subscribedCentrals[self.characteristic!])
    }
    
}


