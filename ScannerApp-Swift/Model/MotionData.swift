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
    
    func writeToFileInBinaryFormat(rotationRateFileUrl: URL, userAccelerationFileUrl: URL, magneticFieldFileUrl: URL, attitudeFileUrl: URL, gravityFileUrl: URL) {
        
        writeToFileInBinaryFormat(fileUrl: rotationRateFileUrl, t: timestamp.littleEndian, x: rotX.bitPattern.littleEndian, y: rotY.bitPattern.littleEndian, z: rotZ.bitPattern.littleEndian)
        writeToFileInBinaryFormat(fileUrl: userAccelerationFileUrl, t: timestamp.littleEndian, x: accX.bitPattern.littleEndian, y: accY.bitPattern.littleEndian, z: accZ.bitPattern.littleEndian)
        writeToFileInBinaryFormat(fileUrl: magneticFieldFileUrl, t: timestamp.littleEndian, x: magX.bitPattern.littleEndian, y: magY.bitPattern.littleEndian, z: magZ.bitPattern.littleEndian)
        writeToFileInBinaryFormat(fileUrl: attitudeFileUrl, t: timestamp.littleEndian, x: roll.bitPattern.littleEndian, y: pitch.bitPattern.littleEndian, z: yaw.bitPattern.littleEndian)
        writeToFileInBinaryFormat(fileUrl: gravityFileUrl, t: timestamp.littleEndian, x: gravX.bitPattern.littleEndian, y: gravY.bitPattern.littleEndian, z: gravZ.bitPattern.littleEndian)
    }
    
    func writeToFileInAsciiFormat(rotationRateFileUrl: URL, userAccelerationFileUrl: URL, magneticFieldFileUrl: URL, attitudeFileUrl: URL, gravityFileUrl: URL) {
         
        writeToFileInAsciiFormat(fileUrl: rotationRateFileUrl, t: timestamp, x: rotX, y: rotY, z: rotZ)
        writeToFileInAsciiFormat(fileUrl: userAccelerationFileUrl, t: timestamp, x: accX, y: accY, z: accZ)
        writeToFileInAsciiFormat(fileUrl: magneticFieldFileUrl, t: timestamp, x: magX, y: magY, z: magZ)
        writeToFileInAsciiFormat(fileUrl: attitudeFileUrl, t: timestamp, x: roll, y: pitch, z: yaw)
        writeToFileInAsciiFormat(fileUrl: gravityFileUrl, t: timestamp, x: gravX, y: gravY, z: gravZ)
    }
    
    private func writeToFileInBinaryFormat(fileUrl: URL, t: Int64, x: UInt64, y: UInt64, z: UInt64) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [t], count: 8))
            fileHandle.write(Data(bytes: [x], count: 8))
            fileHandle.write(Data(bytes: [y], count: 8))
            fileHandle.write(Data(bytes: [z], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }
    
    private func writeToFileInAsciiFormat(fileUrl: URL, t: Int64, x: Double, y: Double, z: Double) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(t) \(x) \(y) \(z)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }
}
