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
        
        rotationRatePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("rot")!)
        preserveSpaceForHeader(fileUrl: URL(fileURLWithPath: rotationRatePath))
        rotationRateFilePointer = fopen(self.rotationRatePath, "a")
        
        userAccelerationPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("acce")!)
        userAccelerationFilePointer = fopen(self.userAccelerationPath, "w")
        
        magneticFieldPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("mag")!)
        magneticFieldFilePointer = fopen(self.magneticFieldPath, "w")
        
        attitudePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("atti")!)
        attitudeFilePointer = fopen(self.attitudePath, "w")
        
        gravityPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("grav")!)
        gravityFilePointer = fopen(self.gravityPath, "w")
        
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
        
        fclose(rotationRateFilePointer)
        fclose(userAccelerationFilePointer)
        fclose(magneticFieldFilePointer)
        fclose(attitudeFilePointer)
        fclose(gravityFilePointer)
        
        writeImuHeader(fileUrl: URL(fileURLWithPath: rotationRatePath), sensorType: "rot", numOfFrame: numberOfMeasurements)
        
        
        
        return numberOfMeasurements
    }
    
    // this function will write empty line to the file
    private func preserveSpaceForHeader(fileUrl: URL) {
        let numOfHeaderLines = 8 // this might need to be changed if we support more sensors in the future
        for i in 1...numOfHeaderLines {
            do {
                try "Line \(i)\n".data(using: .utf8)?.write(to: fileUrl, options: .withoutOverwriting)
            } catch {
                print("error writing to \(fileUrl.absoluteString)")
            }
        }
    }
    
    private func writeImuHeader(fileUrl: URL, sensorType: String, numOfFrame: Int) {
        var header: String = ""
        
        header += "format binary_little_endian 1.0\n"
        header += "element \(sensorType) \(numOfFrame)\n"
        header += "comment\n"
        
        switch sensorType {
        case Constants.Sensor.Imu.RotationRate.type,
             Constants.Sensor.Imu.UserAcceleration.type,
             Constants.Sensor.Imu.MagneticField.type,
             Constants.Sensor.Imu.Gravity.type:
            header += "property long timestamp\n"
            header += "property double x\n"
            header += "property double y\n"
            header += "property double z\n"
        case Constants.Sensor.Imu.Attitude.type:
            header += "property long timestamp\n"
            header += "property double roll\n"
            header += "property double pitch\n"
            header += "property double yaw\n"
        default:
            print("Invalid sensor type")
            return
        }
        
        header += "end_header\n"
        
        do {
            let fileHandle = try FileHandle(forUpdating: fileUrl)
            fileHandle.seek(toFileOffset: 0)
            fileHandle.write(header.data(using: .utf8)!)
            fileHandle.closeFile()
        } catch {
            print("fail to re-write header.")
        }
    }
}
