//
//  BuggyManager.swift
//  BuggyEngine
//
//  Created by Harvey He on 2019/1/8.
//

import UIKit
import PromiseKit
import CoreBluetooth

class BuggyManager: NSObject {
    
    var connectionIO:CBCharacteristic? = nil, connectionReset:CBCharacteristic? = nil, connectionBaudrate:CBCharacteristic? = nil,betteryCharacteristic:CBCharacteristic? = nil;
    fileprivate var manager = BluetoothManager.getInstance()
    fileprivate var (getDevice, device) = Promise<CBPeripheral>.pending()
    fileprivate var (getService, servie) = Promise<String>.pending()
    fileprivate var (getCharacteritic, characteritic) = Promise<String>.pending()
    private var timeOutTask:Task?
    fileprivate var (getBuggyResponse,response) = Promise<[UInt8]>.pending()
    var pageSize:Int = 128
    fileprivate var stkInSync:Bool = false
    fileprivate var getBleData:[UInt8] = []
    fileprivate var getData:[UInt8] = []
    var communucationType:CommunucationType = .control
    var delegate:BuggyManagerDelegate?
    
    static private var instance : BuggyManager {
        return sharedInstance
    }
    static private let sharedInstance = BuggyManager()
    
    static func getInstance() -> BuggyManager {
        return instance
    }
    
    func initCentralManager() -> Promise<BluetoothManager> {
        return Promise {seal in
            manager = BluetoothManager.getInstance();
            if(manager.state == .poweredOn){
                seal.fulfill(manager);
            }else{
                seal.reject(BuggyError(code:.powerOff))
            }
        }
    }
    
    func disConnected()->Promise<String>{
        cancel(timeOutTask);
        connectionIO = nil
        connectionBaudrate = nil
        betteryCharacteristic = nil
       (getDevice, device) = Promise<CBPeripheral>.pending()
       (getService, servie) = Promise<String>.pending()
       (getCharacteritic, characteritic) = Promise<String>.pending()
       (getBuggyResponse,response) = Promise<[UInt8]>.pending()
        manager.disconnectPeripheral();
        manager.stopScanPeripheral();
        return Promise{seal in seal.fulfill("OK")}
    }
    
    func connectDevice()->Promise<String>{
        return self.getDevice.then{peripheral in
            return self.connectPeripheral(peripheral)
            }.then{_ in
                return self.getService
            }.then{_ in
                return self.getCharacteritic
            }.then{_ in
                return Promise{seal in seal.fulfill("OK")}
        }
    }
    
    func startScan() ->Promise<String>{
        manager.delegate = self
        manager.startScanPeripheral()
        //通过外层判断扫描超时
//        timeOutTask = delay(10){
//            self.device.reject(BuggyError(code:.timeOut))
//        }
        return Promise{seal in seal.fulfill("OK")}
    }
    
    func connectPeripheral(_ peripheral:CBPeripheral)->Promise<String>{
        manager.stopScanPeripheral()
        manager.connectPeripheral(peripheral);
        return Promise{seal in seal.fulfill("OK")}
    }
    
    func stopScan(){
        manager.stopScanPeripheral()
    }
    
    func sendDataWithResponse(msg:Array<UInt8>)->Promise<[UInt8]>{
        if let connectionIO = self.connectionIO {
            managerWriteValue(connectionIO, msg:msg)
            timeOutTask = delay(2){self.response.reject(BuggyError(code:.timeOut))}
            return getBuggyResponse
        }else{
            return Promise(error:BuggyError(code:.timeOut))
        }
    }
    
    func sendDataWithoutResponse(msg:Array<UInt8>){
        if let connectionIO = self.connectionIO {
            self.managerWriteValue(connectionIO, msg: msg)
        }
    }
    
    func managerWriteValue(_ characteristic:CBCharacteristic,msg:Array<UInt8>){
        let sendData = Data(bytes:msg);
        var sendCount:Int = 0;
        let packetSize:Int = 20;
        while (sendCount < sendData.count) {
            let writeBytes =   sendData.subdata(in: sendCount..<(sendData.count > (sendCount + packetSize) ? (sendCount + packetSize) :sendData.count))
            manager.writeValue(data:writeBytes, forCharacteristic:characteristic, type:.withoutResponse)
            sendCount = (sendData.count > (sendCount + packetSize) ? (sendCount + packetSize) :sendData.count)
        }
    }
    
    func parseReceived(inputData:[UInt8]){
        switch communucationType {
        case .control:
            self.controlParseReceived(inputData:inputData)
        case .upload:
            self.uploadParseReceived(inputData:inputData)
        }
    }
    
    func controlParseReceived(inputData:[UInt8]){
        delegate?.firmataReceviceData?(inputData: inputData)
        response.fulfill(inputData);
        (getBuggyResponse,response) = Promise<[UInt8]>.pending()
    }
    
    func uploadParseReceived(inputData:[UInt8]){
        for byte in inputData {
            if(stkInSync){
                if(byte == STK_OK){
                    response.fulfill(inputData);
                    (getBuggyResponse,response) = Promise<[UInt8]>.pending()
                }else{
                    getBleData.append(byte);
                }
            }else{
                if(byte == STK_INSYNC){
                    stkInSync = true;
                    getBleData = [];
                }
            }
        }
    }
    
}

extension BuggyManager:BluetoothDelegate{
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber){
        if let name = peripheral.name {
            if (name.contains(buggyName) && labs(RSSI.intValue)<filterRSSI){
               // cancel(timeOutTask);
                device.fulfill(peripheral)
            }
        }
    }
    
    func didDiscoverServices(_ peripheral: CBPeripheral) {
        for service in peripheral.services!{
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics(characteristicUUID, for: service)
            }else if (service.uuid == betteryServiceUUID){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        servie.fulfill("OK")
    }
    
    
    func didDiscoverCharacteritics(_ service: CBService) {
        for  characteristic in service.characteristics!  {
            switch characteristic.uuid {
            case characteristicUUID[0]:
                self.connectionIO = characteristic
                manager.setNotification(enable: true, forCharacteristic:connectionIO!)
            case characteristicUUID[1]:
                self.connectionReset = characteristic
            case characteristicUUID[2]:
                self.connectionBaudrate = characteristic
            case characteristicUUID[3]:
                self.betteryCharacteristic = characteristic
                manager.readValueForCharacteristic(characteristic: betteryCharacteristic!)
                manager.setNotification(enable: true, forCharacteristic:betteryCharacteristic!)
            default:
                break
            }
        }
        if((self.connectionBaudrate) != nil && self.betteryCharacteristic != nil){
            characteritic.fulfill("OK")
        }
    }
    
    func didReadValueForCharacteristic(_ characteristic: CBCharacteristic) {
        if(characteristic == betteryCharacteristic){
            let data = characteristic.value!
            let num = data.to(type:Int.self)
            if(num < 20){
                delegate?.powerWarning?()
            }
        }else{
            let data = characteristic.value!
            cancel(timeOutTask);
            let array = data.withUnsafeBytes {
                [UInt8](UnsafeBufferPointer(start: $0, count: data.count))
            }
            parseReceived(inputData:array)
        }
    }
    func didUpdateState(_ state: CBCentralManagerState) {
        delegate?.managerState?(state:state)
    }
}


extension BuggyManager{
    
    func setDevice() ->Promise<[UInt8]> {
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.timeOut))}
        managerWriteValue(connectionIO!, msg:cmd)
        return getBuggyResponse
    }
    
    func setUploadBaudrate() -> Promise<String>  {
         communucationType = .upload
        if let connectionBau = connectionBaudrate {
            managerWriteValue(connectionBau, msg:Baud115200)
        }
        return after(seconds:0.20).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func  setCommunicatorBaudrate() -> Promise<String>  {
        communucationType = .control
        if let connectionBau = connectionBaudrate {
            managerWriteValue(connectionBau, msg: Baud115200)
        }
        return after(seconds:0.20).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func checkBuggyState() -> Promise<[UInt8]> {
        timeOutTask = delay(2){
            self.response.reject(BuggyError(code:.lineBreak))
            (self.getBuggyResponse,self.response) = Promise<[UInt8]>.pending()
        }
        if let connectIO =  self.connectionIO {
            self.managerWriteValue(connectIO,msg:[0xF0,0x0D,1,0xF7])
        }
        return getBuggyResponse
    }
    
    func getSync()->Promise<[UInt8]> {
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.timeOut))}
        if let connectIO =  connectionIO {
            managerWriteValue(connectIO,msg:[STK_GET_SYNC,CRC_EOP])
        }
        return getBuggyResponse
    }
    
    func getSignature()->Promise<[UInt8]>{
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.timeOut))}
        if let connectIO = connectionIO {
            managerWriteValue(connectIO,msg:[STK_READ_SIGN, CRC_EOP]);
        }
        return getBuggyResponse
        
    }
    
    func keepSync() ->Promise<[UInt8]> {
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.timeOut))}
        if let connectIO = connectionIO {
            managerWriteValue(connectIO,msg:[STK_GET_SYNC,CRC_EOP]);
        }
        return getBuggyResponse
    }
    
    func resetDevice() ->Promise<String>  {
        if let connectReset = connectionReset {
            managerWriteValue(connectReset, msg: resetCmd);
        }
        return after(seconds:0.30).then{return Promise{seal in seal.fulfill("OK")}}
    }
    
    func enterProgramming ()->Promise<[UInt8]>{
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.uploadFailure))}
        if let connectIO = connectionIO {
            managerWriteValue(connectIO,msg:[STK_ENTER_PROGMODE, CRC_EOP]);
        }
        return getBuggyResponse
    }
    
    func exitProgramming ()->Promise<[UInt8]>{
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.uploadFailure))}
        if let connectIO = connectionIO {
            managerWriteValue(connectIO,msg:[STK_LEAVE_PROGMODE, CRC_EOP]);
        }
        return getBuggyResponse
    }
    
    func getCoreType()->Promise<String>{
        return getSync().then { data in
            return  self.getSignature();
            }.then { data in
               return self.verifySignature(data:data)
            }
    }
    
    func verifySignature(data:[UInt8])->Promise<String>{
        var verifyData = data;
        verifyData.removeFirst();
        verifyData.removeLast();
        
        return Promise { seal in
            if(verifyData.count>2){
                let type = coreTypeList["\(Data(bytes:verifyData).hexEncodedString())"]!
                pageSize = type == "644pa16m" ? 256 :128
                seal.fulfill(type);
            }
            else{
                seal.reject(NSError(domain: "error", code: 101, userInfo: nil))
            }
            
        }
    }
    
    func uploadData(hexData:Data)->Promise<String> {
        var sendCount:Int = 0
        var p : Promise<String> = Promise<String>.value("emptyPromise")
        while (sendCount < hexData.count) {
            
            let writeBytes =  hexData.subdata(in: sendCount..<(hexData.count > (sendCount + pageSize) ? (sendCount + pageSize) :hexData.count))
            let bytes = writeBytes.withUnsafeBytes {
                [UInt8](UnsafeBufferPointer(start: $0, count: writeBytes.count))
            }
            let count = sendCount;
            p = p.then {data in
                return self.loadAddress(pageaddr:count,hexData:hexData);
                }.then { data in
                    return self.loadPage(writeBytes:bytes);
                }.then { _ in
                    return Promise{seal in seal.fulfill("OK")}
            }
            sendCount = (hexData.count > (sendCount + pageSize) ? (sendCount + pageSize) :hexData.count)
        }
        return p;
        
    }
    
    func loadAddress(pageaddr:Int,hexData:Data) ->Promise<[UInt8]> {
        let useaddr:UInt16 = UInt16(pageaddr >> 1);
        let addr_low:UInt8 = UInt8(useaddr & 0xff);
        let addr_high:UInt8 = UInt8((useaddr/256) & 0xff);
        let cmd:[UInt8] = [STK_LOAD_ADDRESS,addr_low,addr_high,CRC_EOP];
        managerWriteValue(connectionIO!, msg: cmd)
        updateProgess(pageaddr:pageaddr, hexData: hexData)
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.uploadFailure))}
        return getBuggyResponse
    }
    
    func updateProgess(pageaddr:Int,hexData:Data){
         let progess = Int((Float(pageaddr) / Float(hexData.count))*100)
        delegate?.hexUploadProgess?(progess:progess)
    }
    
    func loadPage(writeBytes:[UInt8])->Promise<[UInt8]> {
        let bytes_low:UInt8 = UInt8(writeBytes.count & 0xff);
        let bytes_high:UInt8 = UInt8(writeBytes.count >> 8);
        var cmd:[UInt8] = [STK_PROG_PAGE, bytes_high, bytes_low, 0x46];
        cmd = cmd + writeBytes;
        cmd.append(CRC_EOP)
        managerWriteValue(connectionIO!, msg: cmd)
        timeOutTask = delay(2){self.response.reject(BuggyError(code:.uploadFailure))}
        return getBuggyResponse;
    }
}
