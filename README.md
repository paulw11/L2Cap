# L2Cap

Implements L2Cap channel capability in Core Bluetooth.

## Usage ##

Instantiate `L2CapCentral` to discover and connect to peripherals

```
    self.l2capCentral = L2CapCentral()
    
    self.l2capCentral.discoveredPeripheralCallback = { peripheral in
        self.peripheral = peripheral
        self.l2capCentral.connect(peripheral: peripheral) { connection in
            self.connection = connection
            
            self.connection?.receiveCallback = { (connection,data) in
                   print("Received data")
            }
            
            self.connection?.sentDataCallback = { (connection, count) in
                prnit("\(count) bytes sent")
            }
        }
    }

```

Send data by calling `self.connection.send(data: data)`

Instantiate `L2CapPeripheral` to advertise a peripheral and accept connections from centrals

```
    self.peripheral = L2CapPeripheral(connectionHandler: { (connection) in
        self.connection = connection
        self.connection?.receiveCallback = { (connection, data) in
            DispatchQueue.main.async {
                self.bytesReceived += data.count
            }
        }
    })
```

A demonstration project [is available](https://github.com/paulw11/L2CapDemo)


