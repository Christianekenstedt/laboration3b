//
//  SensorTag.swift
//  Laboration3b
//
//  Created by Christian Ekenstedt on 2016-12-05.
//  Copyright © 2016 Christian Ekenstedt. All rights reserved.
//

import Foundation
import CoreBluetooth


let IRSensorSERVICE = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
let IRSensorDATA = CBUUID(string:"F000AA01-0451-4000-B000-000000000000")
let IRSensorNOTIFICATION = CBUUID(string:"F0002902-0451-4000-B000-000000000000")
let IRSensorCONFIGURATION = CBUUID(string:"F000AA02-0451-4000-B000-000000000000")
let IRSensorPERIOD = CBUUID(string:"F000AA03-0451-4000-B000-000000000000")

class SensorTag {
    class func checkCharacteristic(characteristic: CBCharacteristic) -> Bool{
            return IRSensorDATA == characteristic.uuid
    }
    
    class func checkIRService(service: CBService) -> Bool{
        return IRSensorSERVICE == service.uuid
    }
    
}
