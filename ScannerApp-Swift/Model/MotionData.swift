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
        do {
            let fileHandle = try FileHandle(forWritingTo: rotationRateFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [self.timestamp.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.rotX.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.rotY.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.rotZ.bitPattern.littleEndian], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: userAccelerationFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [self.timestamp.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.accX.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.accY.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.accZ.bitPattern.littleEndian], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: magneticFieldFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [self.timestamp.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.magX.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.magY.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.magZ.bitPattern.littleEndian], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: attitudeFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [self.timestamp.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.roll.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.pitch.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.yaw.bitPattern.littleEndian], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: gravityFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write(Data(bytes: [self.timestamp.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.gravX.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.gravY.bitPattern.littleEndian], count: 8))
            fileHandle.write(Data(bytes: [self.gravZ.bitPattern.littleEndian], count: 8))
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }
    
    func writeToFileInAsciiFormat(rotationRateFileUrl: URL, userAccelerationFileUrl: URL, magneticFieldFileUrl: URL, attitudeFileUrl: URL, gravityFileUrl: URL) {
         
        do {
            let fileHandle = try FileHandle(forWritingTo: rotationRateFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(timestamp) \(rotX) \(rotY) \(rotZ)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: userAccelerationFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(timestamp) \(accX) \(accY) \(accZ)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: magneticFieldFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(timestamp) \(magX) \(magY) \(magZ)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: attitudeFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(timestamp) \(roll) \(pitch) \(yaw)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: gravityFileUrl)
            fileHandle.seekToEndOfFile()
            fileHandle.write("\(timestamp) \(gravX) \(gravY) \(gravZ)\n".data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print(error)
        }
    }
}
