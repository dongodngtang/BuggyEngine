//
//  Constants.swift
//  Swift-LightBlue
//
//  Created by Pluto Y on 4/20/16.
//  Copyright © 2016 Pluto-y. All rights reserved.
//

import Foundation
import CoreBluetooth
enum PeripheralNotificationKeys : String { // The notification name of peripheral
    case DisconnectNotif = "disconnectNotif" // Disconnect notification name
    case CharacteristicNotif = "characteristicNotif" // Characteristic discover notification name 
}
enum CommunucationType {
    case control
    case upload
}

enum ErrorCode {
    case powerOff
    case timeOut
    case uploadFailure
}

public struct BuggyError: Error {
    let code: ErrorCode
}

/* STK500 constants list, from AVRDUDE */
let STK_OK:UInt8 =             0x10;
let STK_INSYNC:UInt8 =         0x14; // ' '
let CRC_EOP:UInt8 =            0x20;  // 'SPACE'
let STK_GET_SYNC:UInt8 =       0x30;  // '0'
let STK_SET_DEVICE:UInt8 =     0x42;  // 'B'
let STK_ENTER_PROGMODE:UInt8 = 0x50;  // 'P'
let STK_LEAVE_PROGMODE:UInt8 = 0x51;  // 'Q'
let STK_LOAD_ADDRESS:UInt8 =   0x55;  // 'U'
let STK_PROG_PAGE:UInt8 =      0x64;  // 'd'
let STK_READ_SIGN:UInt8 =      0x75;  // 'u'
let cmd:[UInt8] = [0x42,0,0,0,0,0, 0,0,0,0,0,0, 0,0,128, 0,0, 0,0,0, 0,0x20]
let resetCmd:[UInt8] = [0xA5];


/* mCookie message */
let buggyName:String = "mCookie";
let filterRSSI:Int = 50;
let Baud115200:[UInt8] = [UInt8(1152 & 0xFF), UInt8(1152 >> 8)];
let Baud57600:[UInt8] = [UInt8(576 & 0xFF), UInt8(576 >> 8)];
let coreTypeList=["1e960a":"644pa16m","1e9608":"644pa8m"]
let serviceUUID = CBUUID(string:"FFF0")
let betteryServiceUUID = CBUUID(string:"180F")
let characteristicUUID = [CBUUID(string:"FFF6"),CBUUID(string:"FFF1"),CBUUID(string:"FFF2"),CBUUID(string:"2A19")]

//js中的firmata调原生方法
let FIRMATA_CONNECT = "bleConnect"
let FIRMATA_SENDMEG = "sendMsgPromise"
let FIRMATA_TIMEOUT = "connectTimeOut"
let FIRMATA_DISCONNECT = "disconnect"
let FIRMATA_CONNECTREADY = "connectReady"
let FIRMATA_NOTIFICATION = "handleNotification"
let FIRMATA_VERSIONEXPIRED = "versionExpired"

