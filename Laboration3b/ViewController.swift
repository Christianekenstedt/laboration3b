//
//  ViewController.swift
//  Laboration3b
//
//  Created by Christian Ekenstedt on 2016-12-05.
//  Copyright © 2016 Christian Ekenstedt. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate,
CBPeripheralDelegate {

    @IBOutlet weak var collectButton: UIButton!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentRefreshrate: UILabel!
    
    var DEVICE_NAME = "SensorTag"
    var manager : CBCentralManager? = nil
    var peripheral : CBPeripheral? = nil
    var listOfPeripheral : [CBPeripheral] = []
    var collectData : Bool = false
    
    var IRConfigChar : CBCharacteristic? = nil
    var IRPeriodChar : CBCharacteristic? = nil
    
    var enable = 1
    var enableBytes : NSData? = nil
    
    var disable = 0
    var disableBytes : NSData? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        manager = CBCentralManager(delegate: self, queue: nil)
        enableBytes = NSData(bytes: &enable, length: MemoryLayout<UInt8>.size)
        disableBytes = NSData(bytes: &disable, length: MemoryLayout<UInt8>.size)
    }

    
    @IBAction func collectButtonPressed(_ sender: Any) {
        if peripheral != nil && !collectData{
            
            collectButton.setTitle("Stop", for: .normal)
            collectData = true
            startIRSensor()
        }else{
            collectButton.setTitle("Poll", for: .normal)
            stopIRSensor()
            tempLabel.text = "--.--℃"
            collectData = false
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("Started scanning...")
            statusLabel.text = "Scanning..."
            central.scanForPeripherals(withServices: nil, options: nil)
            
        }else{
            print("Bluetooth is not avaliable.")
            statusLabel.text = "Bluetooth is not avaliable."
        }
    }
    

    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected to \(peripheral.name!)!")
        statusLabel.text = "Connected to \(peripheral.name!)!"
        peripheral.discoverServices(nil)
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("did fail to connect")
        statusLabel.text = "Failed to \(peripheral.name!)!"
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Did discover device!")
        if ((peripheral.name?.range(of: DEVICE_NAME)) != nil) {
            print("Found device with name \(DEVICE_NAME)!")
            statusLabel.text = "Found device with name \(DEVICE_NAME)!"
            self.manager?.stopScan()
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            manager?.connect(peripheral, options: nil)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            let thisService = service 
            if SensorTag.checkIRService(service: thisService){
                print("Found IRTemp service")
                peripheral.discoverCharacteristics(nil, for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for char in service.characteristics!{
            print("Did discover IRTemperature characteristic")
            print("trying to enable ir sensor...")
            if IRSensorDATA == char.uuid{
                self.peripheral?.setNotifyValue(true, for: char)
            }
            if IRSensorCONFIGURATION == char.uuid{
                IRConfigChar = char
            }
            if IRSensorPERIOD == char.uuid{
                IRPeriodChar = char
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == IRSensorDATA{
            let dbytes = characteristic.value! as NSData
            let byteLegth = dbytes.length
            var array = [Int16](repeating: 0, count: byteLegth)
            dbytes.getBytes(&array, length: (byteLegth*MemoryLayout<Int16>.size))
            let temp = Double(array[1])/128
            self.tempLabel.text = String(format: "%.2f℃", temp)
        }
        if characteristic.uuid == IRSensorPERIOD{
            let dbytes = characteristic.value! as NSData
            let byteLegth = dbytes.length
            var array = [Int16](repeating: 0, count: byteLegth)
            dbytes.getBytes(&array, length: (byteLegth*MemoryLayout<Int16>.size))
            let temp = Double(array[0])
            print("Answer: \(temp)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        IRConfigChar = nil
        IRPeriodChar = nil
        collectButton.setTitle("Poll", for: .normal)
        slider.value = 100
        currentRefreshrate.text = String(slider.value*10)
        statusLabel.text = "Disconnected..."
        tempLabel.text = "--.--℃"
        collectData = false
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopIRSensor(){
        if IRConfigChar != nil {
            self.peripheral?.writeValue(disableBytes as! Data, for: IRConfigChar!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func startIRSensor(){
        if IRConfigChar != nil{
            self.peripheral?.writeValue(enableBytes as! Data, for: IRConfigChar!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func changeRefreshRate(rate : Int){
        if rate >= 30 && rate <= 255{
            let hex = String(rate, radix: 16)
            peripheral?.writeValue(hex.hexadecimal()!, for: IRPeriodChar!, type: CBCharacteristicWriteType.withResponse)
            peripheral?.readValue(for: IRPeriodChar!)

        }else{
            print("invalid rate")
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == IRSensorPERIOD {
            if error != nil {
               print("\(error)")
            }
        }
    }
    
    @IBAction func sliderDidChange(_ sender: UISlider) {
        currentRefreshrate.text = String(slider.value*10)
        changeRefreshRate(rate: Int(slider.value))
    }
    
    
}

extension String {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a `Data` object. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    func hexadecimal() -> Data? {
        var data = Data(capacity: characters.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, options: [], range: NSMakeRange(0, characters.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else {
            return nil
        }
        
        return data
    }
}
