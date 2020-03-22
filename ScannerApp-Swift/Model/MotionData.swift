//
//  MotionData.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-28.
//  Copyright © 2019 jx16. All rights reserved.
//

import CoreMotion
import Foundation

class MotionData: CustomData {
    
    private var timestamp: Int64
//    private var timestamp: UInt64
    private var rotX: UInt64
    private var rotY: UInt64
    private var rotZ: UInt64
    private var accX: UInt64
    private var accY: UInt64
    private var accZ: UInt64
    private var magX: UInt64
    private var magY: UInt64
    private var magZ: UInt64
    private var roll: UInt64
    private var pitch: UInt64
    private var yaw: UInt64
    private var gravX: UInt64
    private var gravY: UInt64
    private var gravZ: UInt64

    init(deviceMotion data: CMDeviceMotion) {
        
//        self.timestamp = data.timestamp.bitPattern.littleEndian
        self.timestamp = Int64(data.timestamp * 1_000_000_000.0).littleEndian
        
        self.rotX = data.rotationRate.x.bitPattern.littleEndian
        self.rotY = data.rotationRate.y.bitPattern.littleEndian
        self.rotZ = data.rotationRate.z.bitPattern.littleEndian
        
//        print(Int64(data.timestamp * 1_000_000_000.0))
//        print(data.rotationRate.x)
//        print(data.rotationRate.y)
//        print(data.rotationRate.z)
//        print(data.timestamp.bitPattern.littleEndian)
//        print(data.rotationRate.x.bitPattern.littleEndian)
//        print(data.rotationRate.y.bitPattern.littleEndian)
//        print(data.rotationRate.z.bitPattern.littleEndian)
//        print()
        
        self.accX = data.userAcceleration.x.bitPattern.littleEndian
        self.accY = data.userAcceleration.y.bitPattern.littleEndian
        self.accZ = data.userAcceleration.z.bitPattern.littleEndian
        
        self.magX = data.magneticField.field.x.bitPattern.littleEndian
        self.magY = data.magneticField.field.y.bitPattern.littleEndian
        self.magZ = data.magneticField.field.z.bitPattern.littleEndian
        
        self.roll = data.attitude.roll.bitPattern.littleEndian
        self.pitch = data.attitude.pitch.bitPattern.littleEndian
        self.yaw = data.attitude.yaw.bitPattern.littleEndian
        
        self.gravX = data.gravity.x.bitPattern.littleEndian
        self.gravY = data.gravity.y.bitPattern.littleEndian
        self.gravZ = data.gravity.z.bitPattern.littleEndian
    }
    
    init(deviceMotion data: CMDeviceMotion, bootTime: Double) {
        
        let actualTime = data.timestamp + bootTime
        
        self.timestamp = Int64(actualTime * 1_000_000_000.0).littleEndian
        
        self.rotX = data.rotationRate.x.bitPattern.littleEndian
        self.rotY = data.rotationRate.y.bitPattern.littleEndian
        self.rotZ = data.rotationRate.z.bitPattern.littleEndian
        
//        print(Int64(actualTime * 1_000_000_000.0))
//        print(data.rotationRate.x)
//        print(data.rotationRate.y)
//        print(data.rotationRate.z)
//        print(data.timestamp.bitPattern.littleEndian)
//        print(data.rotationRate.x.bitPattern.littleEndian)
//        print(data.rotationRate.y.bitPattern.littleEndian)
//        print(data.rotationRate.z.bitPattern.littleEndian)
//        print()
        
        self.accX = data.userAcceleration.x.bitPattern.littleEndian
        self.accY = data.userAcceleration.y.bitPattern.littleEndian
        self.accZ = data.userAcceleration.z.bitPattern.littleEndian
        
        self.magX = data.magneticField.field.x.bitPattern.littleEndian
        self.magY = data.magneticField.field.y.bitPattern.littleEndian
        self.magZ = data.magneticField.field.z.bitPattern.littleEndian
        
        self.roll = data.attitude.roll.bitPattern.littleEndian
        self.pitch = data.attitude.pitch.bitPattern.littleEndian
        self.yaw = data.attitude.yaw.bitPattern.littleEndian
        
        self.gravX = data.gravity.x.bitPattern.littleEndian
        self.gravY = data.gravity.y.bitPattern.littleEndian
        self.gravZ = data.gravity.z.bitPattern.littleEndian
    }
    
    func display() {
        print("System Uptime: \(self.timestamp)")
        print("Rotation: \(self.rotX), \(self.rotY), \(self.rotZ)")
        print("Acceleration: \(self.accX), \(self.accY), \(self.accZ)")
        print("Magnetic Field: \(self.magX), \(self.magY), \(self.magZ)")
        print("Roll: \(self.roll)")
        print("Pitch: \(self.pitch)")
        print("Yaw: \(self.yaw)")
        print("Gravity: \(self.gravX), \(self.gravY), \(self.gravZ)")
    }
    
    func writeToFile(filepath: String) {
        let filePointer = fopen(filepath, "w")
        writeToFile(filePointer: filePointer!)
        fclose(filePointer)
    }
    
    func writeToFile(filePointer: UnsafeMutablePointer<FILE>) {
//        fwrite(UnsafePointer<UInt64>(&self.timestamp), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.rotX), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.rotY), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.rotZ), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.accX), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.accY), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.accZ), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.magX), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.magY), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.magZ), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.roll), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.pitch), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.yaw), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravX), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravY), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravZ), 8, 1, filePointer)

        fflush(filePointer)
    }
    
    func writeToFiles(rotationRateFilePointer: UnsafeMutablePointer<FILE>, userAccelerationFilePointer: UnsafeMutablePointer<FILE>, magneticFieldFilePointer: UnsafeMutablePointer<FILE>, attitudeFilePointer: UnsafeMutablePointer<FILE>, gravityFilePointer: UnsafeMutablePointer<FILE>) {
        
        fwrite(UnsafePointer<Int64>([self.timestamp]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotX]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotY]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotZ]), 8, 1, rotationRateFilePointer)
        fflush(rotationRateFilePointer)
        
        fwrite(UnsafePointer<Int64>(&self.timestamp), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.accX), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.accY), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.accZ), 8, 1, userAccelerationFilePointer)
        fflush(userAccelerationFilePointer)

        fwrite(UnsafePointer<Int64>(&self.timestamp), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.magX), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.magY), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.magZ), 8, 1, magneticFieldFilePointer)
        fflush(magneticFieldFilePointer)

        fwrite(UnsafePointer<Int64>(&self.timestamp), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.roll), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.pitch), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.yaw), 8, 1, attitudeFilePointer)
        fflush(attitudeFilePointer)

        fwrite(UnsafePointer<Int64>(&self.timestamp), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravX), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravY), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>(&self.gravZ), 8, 1, gravityFilePointer)
        fflush(gravityFilePointer)
    }
}
