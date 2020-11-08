//
//  File.swift
//  
//
//  Created by Paul Wilkinson on 13/12/19.
//

import Foundation
import CoreBluetooth

class L2CapInternalConnection: NSObject, StreamDelegate, L2CapConnection {
    
    var channel: CBL2CAPChannel?
    
    public var receiveCallback:L2CapReceiveDataCallback?
    public var sentDataCallback: L2CapSentDataCallback?
    
    private var queueQueue = DispatchQueue(label: "queue queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    
    private var outputData = Data()
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.openCompleted:
            print("Stream is open")
        case Stream.Event.endEncountered:
            print("End Encountered")
        case Stream.Event.hasBytesAvailable:
            print("Bytes are available")
            self.readBytes(from: aStream as! InputStream)
        case Stream.Event.hasSpaceAvailable:
            print("Space is available")
            self.send()
        case Stream.Event.errorOccurred:
            print("Stream error")
        default:
            print("Unknown stream event")
        }
    }
    
    deinit {
        print("Going away")
    }
    
    
    public func send(data: Data) -> Void {
        queueQueue.sync  {
            self.outputData.append(data)
        }
        self.send()
    }
    
    private func send() {
        
        guard let ostream = self.channel?.outputStream, !self.outputData.isEmpty, ostream.hasSpaceAvailable  else{
            return
        }
        let bytesWritten =  ostream.write(self.outputData)
        
        print("bytesWritten = \(bytesWritten)")
        self.sentDataCallback?(self,bytesWritten)
        queueQueue.sync {
            if bytesWritten < outputData.count {
                outputData = outputData.advanced(by: bytesWritten)
            } else {
                outputData.removeAll()
            }
        }
    }
    
    private func readBytes(from stream: InputStream) {
        let bufLength = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufLength)
        defer {
            buffer.deallocate()
        }
        let bytesRead = stream.read(buffer, maxLength: bufLength)
        var returnData = Data()
        returnData.append(buffer, count:bytesRead)
        self.receiveCallback?(self,returnData)
        if stream.hasBytesAvailable {
            self.readBytes(from: stream)
        }
    }
}

class L2CapCentralConnection: L2CapInternalConnection, CBPeripheralDelegate {
    
    internal init(peripheral: CBPeripheral,connectionCallback: @escaping L2CapConnectionCallback) {
        self.peripheral = peripheral
        self.connectionHandler = connectionCallback
        super.init()
        peripheral.delegate = self
    }
    
    
    private var psmCharacteristic: CBCharacteristic?
    private var peripheral: CBPeripheral
    private let connectionHandler: L2CapConnectionCallback
    
    func discover() {
        self.peripheral.discoverServices([Constants.psmServiceID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Service discovery error - \(error)")
            return
        }
    
        for service in peripheral.services ?? [] {
            if service.uuid == Constants.psmServiceID {
                peripheral.discoverCharacteristics([Constants.PSMID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Characteristic discovery error - \(error)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            print("Discovered characteristic \(characteristic)")
            if characteristic.uuid ==  Constants.PSMID {
                self.psmCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Characteristic update error - \(error)")
            return
        }
        
        if let dataValue = characteristic.value {
            let psm = dataValue.uint16
            print("Opening channel \(psm)")
            self.peripheral.openL2CAPChannel(psm)
        } else {
            print("Problem decoding PSM")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        if let error = error {
            print("Error opening l2cap channel - \(error.localizedDescription)")
            return
        }
        guard let channel = channel else {
            return
        }
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
        self.connectionHandler(self)
    }
}

class L2CapPeripheralConnection: L2CapInternalConnection {
    init(channel: CBL2CAPChannel) {
        super.init()
        self.channel = channel
        channel.inputStream.delegate = self
        channel.outputStream.delegate = self
        channel.inputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.outputStream.schedule(in: RunLoop.main, forMode: .default)
        channel.inputStream.open()
        channel.outputStream.open()
    }
}
