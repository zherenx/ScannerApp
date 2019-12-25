//
//  MotionDataProcessor.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-24.
//  Copyright © 2019 jx16. All rights reserved.
//

import CoreMotion
import Foundation

struct CustomMotionData {
    
    var systemUptime: Double
    var rotX: Double
    var rotY: Double
    var rotZ: Double
    var accX: Double
    var accY: Double
    var accZ: Double
    var magX: Double
    var magY: Double
    var magZ: Double
    var roll: Double
    var pitch: Double
    var yaw: Double
    var gravX: Double
    var gravY: Double
    var gravZ: Double

    init(deviceMotion data: CMDeviceMotion) {
        self.systemUptime = ProcessInfo.processInfo.systemUptime
        
        self.rotX = data.rotationRate.x
        self.rotY = data.rotationRate.y
        self.rotZ = data.rotationRate.z
        
        self.accX = data.userAcceleration.x
        self.accY = data.userAcceleration.y
        self.accZ = data.userAcceleration.z
        
        self.magX = data.magneticField.field.x
        self.magY = data.magneticField.field.y
        self.magZ = data.magneticField.field.z
        
        self.roll = data.attitude.roll
        self.pitch = data.attitude.pitch
        self.yaw = data.attitude.yaw
        
        self.gravX = data.gravity.x
        self.gravY = data.gravity.y
        self.gravZ = data.gravity.z
    }
}

class MotionDataProcessor {
    static func processDeviceMotion(deviceMotion data: CMDeviceMotion) {
//        print(data)
        
        let customMotionData = CustomMotionData(deviceMotion: data)
        
        print("System Uptime: \(customMotionData.systemUptime)")
        print("Rotation: \(customMotionData.rotX), \(customMotionData.rotY), \(customMotionData.rotZ)")
        print("Acceleration: \(customMotionData.accX), \(customMotionData.accY), \(customMotionData.accZ)")
        print("Magnetic Field: \(customMotionData.magX), \(customMotionData.magY), \(customMotionData.magZ)")
        print("Roll: \(customMotionData.roll)")
        print("Pitch: \(customMotionData.pitch)")
        print("Yaw: \(customMotionData.yaw)")
        print("Gravity: \(customMotionData.gravX), \(customMotionData.gravY), \(customMotionData.gravZ)")
    }
    
    static func processDeviceMotionAndWriteToFile(deviceMotion data: CMDeviceMotion, filePointer: UnsafeMutablePointer<FILE>) {

        var customData = CustomMotionData(deviceMotion: data)
        
//        let filePointer = fopen(filePath, "a")
        
        fwrite(UnsafePointer<Double>(&customData.systemUptime), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.rotX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.rotY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.rotZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.accX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.accY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.accZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.magX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.magY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.magZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.roll), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.pitch), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.yaw), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.gravX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.gravY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&customData.gravZ), 8, 1, filePointer)
        
        fflush(filePointer)
    }
}
