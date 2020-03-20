//
//  MotionManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-03-19.
//  Copyright © 2020 jx16. All rights reserved.
//

import CoreMotion
import Foundation

class MotionManager {
    
    // is it necessary to make this a singleton class??
    static let instance = MotionManager()
    
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    
    private var isRecording: Bool = false
    private var numberOfMeasurements: Int = 0
    
    
    
    
    private var rotationRatePath: String!
    private var userAccelerationPath: String!
    private var magneticFieldPath: String!
    private var attitudePath: String!
    private var gravityPath: String!
    
    private var rotationRateFilePointer: UnsafeMutablePointer<FILE>?
    private var userAccelerationFilePointer: UnsafeMutablePointer<FILE>?
    private var magneticFieldFilePointer: UnsafeMutablePointer<FILE>?
    private var attitudeFilePointer: UnsafeMutablePointer<FILE>?
    private var gravityFilePointer: UnsafeMutablePointer<FILE>?
    
    
    
    
    
    
    private init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / Double(Constants.Sensor.Imu.frequency)
        motionQueue.maxConcurrentOperationCount = 1
    }
    
    func startRecording(dataPathString: String, fileId: String) {
        if isRecording {
            // TODO: do something
            return
        }
        
        isRecording = true // should i move this to later?
        numberOfMeasurements = 0
        
        let tempHeader = "#\n"
        
        self.rotationRatePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("rot")!)
        do {
            try tempHeader.write(to: URL(fileURLWithPath: self.rotationRatePath), atomically: true, encoding: .utf8)
        } catch {
            print("fail to write header.")
        }
        self.rotationRateFilePointer = fopen(self.rotationRatePath, "a")
        
        self.userAccelerationPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("acce")!)
        self.userAccelerationFilePointer = fopen(self.userAccelerationPath, "w")
        
        self.magneticFieldPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("mag")!)
        self.magneticFieldFilePointer = fopen(self.magneticFieldPath, "w")
        
        self.attitudePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("atti")!)
        self.attitudeFilePointer = fopen(self.attitudePath, "w")
        
        self.gravityPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("grav")!)
        self.gravityFilePointer = fopen(self.gravityPath, "w")
        
        self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
            if let validData = data {
                self.numberOfMeasurements += 1
                let motionData = MotionData(deviceMotion: validData)
                motionData.display()
                motionData.writeToFiles(rotationRateFilePointer: self.rotationRateFilePointer!, userAccelerationFilePointer: self.userAccelerationFilePointer!, magneticFieldFilePointer: self.magneticFieldFilePointer!, attitudeFilePointer: self.attitudeFilePointer!, gravityFilePointer: self.gravityFilePointer!)
            } else {
                print("there is some problem with motion data")
            }
        }
    }
    
    func stopRecordingAndRetureNumberOfMeasurements() -> Int {
        if !isRecording {
            // TODO: do something
            return -1
        }
        
        self.motionManager.stopDeviceMotionUpdates()
        
        isRecording = false
        
        fclose(self.rotationRateFilePointer)
        fclose(self.userAccelerationFilePointer)
        fclose(self.magneticFieldFilePointer)
        fclose(self.attitudeFilePointer)
        fclose(self.gravityFilePointer)
        
        
        let endian = "little"
        let rotHeader = "#rot \(self.numberOfMeasurements) 3 \(endian)\n";
        do {
            let fileHandle = try FileHandle(forUpdating: URL(fileURLWithPath: self.rotationRatePath))
            fileHandle.seek(toFileOffset: 0)
            fileHandle.write(rotHeader.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            print("fail to re-write header.")
        }
        
        
        
        return numberOfMeasurements
    }
}
