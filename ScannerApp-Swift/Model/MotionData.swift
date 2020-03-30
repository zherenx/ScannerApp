//
//  MotionData.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-28.
//  Copyright © 2019 jx16. All rights reserved.
//

import CoreMotion
import Foundation

class MotionData {
    
    private var timestamp: Int64
    private var rotX: Double
    private var rotY: Double
    private var rotZ: Double
    private var accX: Double
    private var accY: Double
    private var accZ: Double
    private var magX: Double
    private var magY: Double
    private var magZ: Double
    private var roll: Double
    private var pitch: Double
    private var yaw: Double
    private var gravX: Double
    private var gravY: Double
    private var gravZ: Double

    init(deviceMotion data: CMDeviceMotion) {
        
        self.timestamp = Int64(data.timestamp * 1_000_000_000.0)
        
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
    
    init(deviceMotion data: CMDeviceMotion, bootTime: Double) {
        
        let actualTime = data.timestamp + bootTime
        
        self.timestamp = Int64(actualTime * 1_000_000_000.0)
        
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
    
    func writeToFile(filePointer: UnsafeMutablePointer<FILE>) {
        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.rotX.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.rotY.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.rotZ.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.accX.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.accY.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.accZ.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.magX.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.magY.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.magZ.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.roll.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.pitch.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.yaw.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.gravX.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.gravY.bitPattern.littleEndian]), 8, 1, filePointer)
        fwrite(UnsafePointer<UInt64>([self.gravZ.bitPattern.littleEndian]), 8, 1, filePointer)

        fflush(filePointer)
    }
    
    func writeToFiles(rotationRateFilePointer: UnsafeMutablePointer<FILE>, userAccelerationFilePointer: UnsafeMutablePointer<FILE>, magneticFieldFilePointer: UnsafeMutablePointer<FILE>, attitudeFilePointer: UnsafeMutablePointer<FILE>, gravityFilePointer: UnsafeMutablePointer<FILE>) {
        
        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotX.bitPattern.littleEndian]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotY.bitPattern.littleEndian]), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<UInt64>([self.rotZ.bitPattern.littleEndian]), 8, 1, rotationRateFilePointer)
        fflush(rotationRateFilePointer)
        
        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>([self.accX.bitPattern.littleEndian]), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>([self.accY.bitPattern.littleEndian]), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<UInt64>([self.accZ.bitPattern.littleEndian]), 8, 1, userAccelerationFilePointer)
        fflush(userAccelerationFilePointer)

        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>([self.magX.bitPattern.littleEndian]), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>([self.magY.bitPattern.littleEndian]), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<UInt64>([self.magZ.bitPattern.littleEndian]), 8, 1, magneticFieldFilePointer)
        fflush(magneticFieldFilePointer)

        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>([self.roll.bitPattern.littleEndian]), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>([self.pitch.bitPattern.littleEndian]), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<UInt64>([self.yaw.bitPattern.littleEndian]), 8, 1, attitudeFilePointer)
        fflush(attitudeFilePointer)

        fwrite(UnsafePointer<Int64>([self.timestamp.littleEndian]), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>([self.gravX.bitPattern.littleEndian]), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>([self.gravY.bitPattern.littleEndian]), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<UInt64>([self.gravZ.bitPattern.littleEndian]), 8, 1, gravityFilePointer)
        fflush(gravityFilePointer)
    }
}
