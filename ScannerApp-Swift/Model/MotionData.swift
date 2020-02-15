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
    
    private var systemUptime: Double
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
    
    func display() {
        print("System Uptime: \(self.systemUptime)")
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
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.rotX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.rotY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.rotZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.accX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.accY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.accZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.magX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.magY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.magZ), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.roll), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.pitch), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.yaw), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.gravX), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.gravY), 8, 1, filePointer)
        fwrite(UnsafePointer<Double>(&self.gravZ), 8, 1, filePointer)
        
        fflush(filePointer)
    }
    
    func writeToFiles(rotationRateFilePointer: UnsafeMutablePointer<FILE>, userAccelerationFilePointer: UnsafeMutablePointer<FILE>, magneticFieldFilePointer: UnsafeMutablePointer<FILE>, attitudeFilePointer: UnsafeMutablePointer<FILE>, gravityFilePointer: UnsafeMutablePointer<FILE>) {
        
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<Double>(&self.rotX), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<Double>(&self.rotY), 8, 1, rotationRateFilePointer)
        fwrite(UnsafePointer<Double>(&self.rotZ), 8, 1, rotationRateFilePointer)
        fflush(rotationRateFilePointer)
        
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<Double>(&self.accX), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<Double>(&self.accY), 8, 1, userAccelerationFilePointer)
        fwrite(UnsafePointer<Double>(&self.accZ), 8, 1, userAccelerationFilePointer)
        fflush(userAccelerationFilePointer)
        
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<Double>(&self.magX), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<Double>(&self.magY), 8, 1, magneticFieldFilePointer)
        fwrite(UnsafePointer<Double>(&self.magZ), 8, 1, magneticFieldFilePointer)
        fflush(magneticFieldFilePointer)
        
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<Double>(&self.roll), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<Double>(&self.pitch), 8, 1, attitudeFilePointer)
        fwrite(UnsafePointer<Double>(&self.yaw), 8, 1, attitudeFilePointer)
        fflush(attitudeFilePointer)
        
        fwrite(UnsafePointer<Double>(&self.systemUptime), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<Double>(&self.gravX), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<Double>(&self.gravY), 8, 1, gravityFilePointer)
        fwrite(UnsafePointer<Double>(&self.gravZ), 8, 1, gravityFilePointer)
        fflush(gravityFilePointer)
    }
}
