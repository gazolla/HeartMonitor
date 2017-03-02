//
//  MainViewController.swift
//  HRM
//
//  Created by Sebastiao Gazolla Costa Junior on 04/01/17.
//  Copyright © 2017 Sebastiao Gazolla Costa Junior. All rights reserved.
//

import UIKit
import CoreBluetooth

struct HeartRate {
    let BPM:Int
    let intensity:Int?
}

class HeartRateMonitor: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private enum BlueToothGATTServices: UInt16 {
        case BatteryService    = 0x180F
        case DeviceInformation = 0x180A
        case HeartRate         = 0x180D
        
        var UUID: CBUUID {
            return CBUUID(string: String(self.rawValue, radix: 16, uppercase: true))
        }
    }
    
    let STORED_PERIPHERAL_IDENTIFIER = "STORED_PERIPHERAL_IDENTIFIER"
    var centralManager: CBCentralManager!
    var heartMonitor: CBPeripheral?
    var heartMonitorList:[DisplayPeripheral]?
    var birthday: Date?
    private var isScanning = false
    
    var hrMax:Int? {
        get {
            if self.birthday != nil {
                return self.getHRMax(birthday: self.birthday!)
            } else {
                return nil
            }
        }
    }

    var update: ((_ hr:HeartRate)->())?
    var updateMessage: ((_ msg:String)->())?
    var updateList: ((_ list:[DisplayPeripheral])->())?
    var updateStopScan: (()->())?

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(">>>>>>>>> centralManagerDidUpdateState")
        
        switch central.state {
            
        case CBManagerState.poweredOff:
            NSLog("CoreBluetooth BLE hardware is powered off");
        case CBManagerState.poweredOn:
            NSLog("CoreBluetooth BLE hardware is powered on and ready");
            self.updateMessage?("Bluetooth ligado")
            startRetrieving()

        case CBManagerState.unauthorized:
            NSLog("CoreBluetooth BLE hardware is unauthorized");
            
        case CBManagerState.resetting:
            NSLog("CoreBluetooth BLE hardware is resetting");
            
        case CBManagerState.unknown:
            NSLog("CoreBluetooth BLE hardware is unknown");
            
        case CBManagerState.unsupported:
            NSLog("CoreBluetooth BLE hardware is unsupported");
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print(">>>>>>>>> didConnect peripheral")
        print(">>>>>>>>> peripheral uuid =>> \(peripheral.identifier.uuidString)")
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(peripheral.identifier.uuidString, forKey: STORED_PERIPHERAL_IDENTIFIER)
        userDefaults.synchronize()
        
        self.heartMonitor = peripheral
        self.heartMonitor!.delegate = self
        self.heartMonitor!.discoverServices(nil)
        let connected = "Connected: " + (self.heartMonitor!.state == CBPeripheralState.connected ? "YES" : "NO")
        print("\(connected)")
        self.updateMessage?("Connected.")

    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(">>>>>>>>> didDiscover peripheral")
        for (index, foundPeripheral) in heartMonitorList!.enumerated(){
            if foundPeripheral.peripheral.identifier == peripheral.identifier{
                heartMonitorList![index].lastRSSI = RSSI
                return
            }
        }
        
        let sensorName:String
        if let localName:String = advertisementData[CBAdvertisementDataLocalNameKey] as! String? {
            sensorName = localName
        } else if let localName:String = peripheral.name{
            sensorName = localName
        } else {
            sensorName = "No Device Name"
        }
        
        let displayPeripheral:DisplayPeripheral = DisplayPeripheral(name: sensorName, lastRSSI: RSSI, peripheral: peripheral)
        heartMonitorList!.append(displayPeripheral)
        self.updateList?(self.heartMonitorList!)
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if error != nil { print(" didDisconnectPeripheral:: \(error!)") }
        self.heartMonitor?.delegate = nil
        self.updateMessage?("Desconnected.")
        let hr = HeartRate(BPM: 0, intensity: 0)
        self.update?(hr)
        startRetrieving()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil { print(" didDiscoverServices:: \(error!)") }
        for service in peripheral.services!
        {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service )
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil { print(" didDiscoverCharacteristicsFor:: \(error!)") }
        if service.uuid == CBUUID(string: "0x180D") {
            for characteristic in service.characteristics as [CBCharacteristic]!{
                print("Discovered characteristic: \(characteristic.uuid)")
                if characteristic.properties.contains(CBCharacteristicProperties.notify) {
                    peripheral.discoverDescriptors(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil { print(" didUpdateValueFor:: \(error!)") }
        if characteristic.uuid == CBUUID(string: "0x2A37") {
            self.getHeartBPMData(characteristic: characteristic, error: error)
        }
    }
    
    func startRetrieving(){
        let userDefaults = UserDefaults.standard
        let peripheralUUID = userDefaults.string(forKey: STORED_PERIPHERAL_IDENTIFIER)
        if (peripheralUUID != nil) {
            print(">>>>>>>>> retrieving Peripheral....")
            print(">>>>>>>>> peripheral uuid =>> \(peripheralUUID)")
            self.updateMessage?("Retrieving sensor...")
            for p:AnyObject in self.centralManager.retrievePeripherals(withIdentifiers: [NSUUID(uuidString:peripheralUUID!) as! UUID]) {
                if p is CBPeripheral {
                    self.heartMonitor = p as? CBPeripheral
                    self.centralManager.connect(self.heartMonitor!, options: nil)
                    print(">>>>>>>>> connecting Peripheral....")
                    self.updateMessage?("Connecting sensor...")
                    return
                }
            }
        } else {
            self.updateMessage?("Registre sensor.")
        }
    }
    
    func startScanning(){
    //    self.updateMessage?("Procurando periféricos...")
        print(">>>>>>>>> startScanning")
        
        self.heartMonitorList = []
        self.updateList?(self.heartMonitorList!)
        self.isScanning = true
        let services = [
            BlueToothGATTServices.DeviceInformation.UUID,
            BlueToothGATTServices.HeartRate.UUID,
            BlueToothGATTServices.BatteryService.UUID
        ]
        self.centralManager.scanForPeripherals(withServices:services, options: nil)
        NSLog("Services: \(services.description)")
        
        let triggerTime = (Int64(NSEC_PER_SEC) * 10)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(triggerTime) / Double(NSEC_PER_SEC), execute: { () -> Void in
            self.stopScanning()
        })
    }
    
    public func stopScanning() {
        print(">>>>>>>>> stopScanning")
        if (self.isScanning) {
            self.isScanning = false
            self.centralManager.stopScan()
            self.updateStopScan?()
        }
    }
    
    public func registerPeripheral(peripheral:CBPeripheral){
    
    }
    
    public func removePeripheral() {
        print(">>>>>>>>> removePeripheral")
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: STORED_PERIPHERAL_IDENTIFIER)
        userDefaults.synchronize()
        disconnect()
    }
    
    public func isPeripheralRegistered()->Bool{
        let userDefaults = UserDefaults.standard
        let peripheralUUID = userDefaults.string(forKey: STORED_PERIPHERAL_IDENTIFIER)
        return (peripheralUUID != nil)
    }
    
    func disconnect(){
        print(">>>>>>>>> disconnect")
        if heartMonitor != nil {
            print("disconnecting.....")
            self.centralManager.cancelPeripheralConnection(heartMonitor!)
            self.heartMonitor = nil
            print("disconnected")
        }
    }
    
    func getHeartBPMData(characteristic: CBCharacteristic, error: Error?) {
        if error != nil { print(" getHeartBPMData:: \(error!)") }
        guard let data = characteristic.value else { return }
        
        let count = data.count / MemoryLayout<UInt8>.size
        var array = [UInt8](repeating: 0, count: count)
        data.copyBytes(to: &array, count:count * MemoryLayout<UInt8>.size)
        
        if ((array[0] & 0x01) == 0) {
            let bpm = array[1]
            let bpmInt = Int(bpm)
            let hr = HeartRate(BPM: bpmInt, intensity: self.getHRIntensity(hr: bpmInt))
            self.update?(hr)
        }
        
    }
    
    func getAge(birthday:Date)->Int{
        let now: Date! = Date()
        let calendar = NSCalendar.current as NSCalendar
        let ageComponents = calendar.components([.year], from: birthday, to: now)
        let age = ageComponents.year!
        return age
    }
    
    func getHRMax(birthday:Date)->Int {
        return 220 - getAge(birthday: birthday)
    }
    
    func getHRIntensity(hr:Int)->Int?{
        if self.hrMax != nil {
            return (hr*100) / self.hrMax!
        } else {
            return nil
        }
    }

}
