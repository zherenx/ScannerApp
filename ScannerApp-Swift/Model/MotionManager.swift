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
    
    enum MotionManagerError: Error {
        case imuSensorInUnexpectedStateError
    }
    
    // is it necessary to make this a singleton class??
    static let instance = MotionManager()
    
    private let motionManager = CMMotionManager()
    private let motionQueue = OperationQueue()
    
//    private let bootTime: Double
    
    private var isRecording: Bool = false
    private var numberOfMeasurements: Int = 0
    
    private var rotationRateFileUrl: URL!
    private var userAccelerationFileUrl: URL!
    private var magneticFieldFileUrl: URL!
    private var attitudeFileUrl: URL!
    private var gravityFileUrl: URL!
    
    private var rotationRateFilePointer: UnsafeMutablePointer<FILE>!
    private var userAccelerationFilePointer: UnsafeMutablePointer<FILE>!
    private var magneticFieldFilePointer: UnsafeMutablePointer<FILE>!
    private var attitudeFilePointer: UnsafeMutablePointer<FILE>!
    private var gravityFilePointer: UnsafeMutablePointer<FILE>!
    
    private init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / Double(Constants.Sensor.Imu.frequency)
        motionQueue.maxConcurrentOperationCount = 1
        
//        bootTime = Helper.bootTime()!
    }
    
    func startRecording(dataPathString: String, fileId: String) {
        if isRecording {
            // TODO: do something
            return
        }
        
        isRecording = true // should i move this to later?
        numberOfMeasurements = 0
        
        let rotationRatePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension(Constants.Sensor.Imu.RotationRate.fileExtension)!)
        rotationRateFileUrl = URL(fileURLWithPath: rotationRatePath)
        createEmptyFile(fileUrl: rotationRateFileUrl)
//        writeImuHeader(fileUrl: rotationRateFileUrl, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrame: -1) // preserve space for header
        rotationRateFilePointer = fopen(rotationRatePath, "a")
        
        let userAccelerationPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension(Constants.Sensor.Imu.UserAcceleration.fileExtension)!)
        userAccelerationFileUrl = URL(fileURLWithPath: userAccelerationPath)
        createEmptyFile(fileUrl: userAccelerationFileUrl)
//        writeImuHeader(fileUrl: userAccelerationFileUrl, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrame: -1) // preserve space for header
        userAccelerationFilePointer = fopen(userAccelerationPath, "a")

        let magneticFieldPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension(Constants.Sensor.Imu.MagneticField.fileExtension)!)
        magneticFieldFileUrl = URL(fileURLWithPath: magneticFieldPath)
        createEmptyFile(fileUrl: magneticFieldFileUrl)
//        writeImuHeader(fileUrl: magneticFieldFileUrl, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrame: -1) // preserve space for header
        magneticFieldFilePointer = fopen(magneticFieldPath, "a")

        let attitudePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension(Constants.Sensor.Imu.Attitude.fileExtension)!)
        attitudeFileUrl = URL(fileURLWithPath: attitudePath)
        createEmptyFile(fileUrl: attitudeFileUrl)
//        writeImuHeader(fileUrl: attitudeFileUrl, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrame: -1) // preserve space for header
        attitudeFilePointer = fopen(attitudePath, "a")

        let gravityPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension(Constants.Sensor.Imu.Gravity.fileExtension)!)
        gravityFileUrl = URL(fileURLWithPath: gravityPath)
        createEmptyFile(fileUrl: gravityFileUrl)
//        writeImuHeader(fileUrl: gravityFileUrl, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrame: -1) // preserve space for header
        gravityFilePointer = fopen(gravityPath, "a")
        
        self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
            if let validData = data {
                self.numberOfMeasurements += 1
                let motionData = MotionData(deviceMotion: validData)
//                let motionData = MotionData(deviceMotion: validData, bootTime: self.bootTime)
                
//                motionData.display()
                
                motionData.writeToFiles(rotationRateFilePointer: self.rotationRateFilePointer!, userAccelerationFilePointer: self.userAccelerationFilePointer!, magneticFieldFilePointer: self.magneticFieldFilePointer!, attitudeFilePointer: self.attitudeFilePointer!, gravityFilePointer: self.gravityFilePointer!)
            } else {
                print("there is some problem with motion data")
            }
        }
    }
    
    func stopRecordingAndReturnNumberOfMeasurements() -> Int {
        do {
            try stopRecording()
        } catch {
            // TODO: do something
            return -1
        }
        
        return numberOfMeasurements
    }
    
    func stopRecordingAndReturnStreamInfo() -> [ImuStreamInfo] {
        do {
            try stopRecording()
        } catch {
            // TODO: do something
            return []
        }
        
        return generateStreamInfo()
    }
    
    func stopRecording() throws {
        if !isRecording {
            print("Imu sensor is not recording when calling stopRecording().")
            
            // TODO: do something
            throw MotionManagerError.imuSensorInUnexpectedStateError
        }
        
        self.motionManager.stopDeviceMotionUpdates()
        
        isRecording = false
        
        fclose(rotationRateFilePointer)
        fclose(userAccelerationFilePointer)
        fclose(magneticFieldFilePointer)
        fclose(attitudeFilePointer)
        fclose(gravityFilePointer)
        
        // rewrite header
        //        writeImuHeader(fileUrl: rotationRateFileUrl, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrame: numberOfMeasurements)
        //        writeImuHeader(fileUrl: userAccelerationFileUrl, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrame: numberOfMeasurements)
        //        writeImuHeader(fileUrl: magneticFieldFileUrl, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrame: numberOfMeasurements)
        //        writeImuHeader(fileUrl: attitudeFileUrl, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrame: numberOfMeasurements)
        //        writeImuHeader(fileUrl: gravityFileUrl, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrame: numberOfMeasurements)
        
        addHeaderToFile(fileUrl: rotationRateFileUrl, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrame: numberOfMeasurements)
        addHeaderToFile(fileUrl: userAccelerationFileUrl, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrame: numberOfMeasurements)
        addHeaderToFile(fileUrl: magneticFieldFileUrl, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrame: numberOfMeasurements)
        addHeaderToFile(fileUrl: attitudeFileUrl, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrame: numberOfMeasurements)
        addHeaderToFile(fileUrl: gravityFileUrl, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrame: numberOfMeasurements)
    }
    
    private func createEmptyFile(fileUrl: URL) {
        do {
            try "".write(to: fileUrl, atomically: true, encoding: .utf8)
        } catch {
            print("fail to create file at \(fileUrl.absoluteString)")
            print(error)
        }
    }
    
    private func writeImuHeader(fileUrl: URL, sensorType: String, numOfFrame: Int) {
        var header: String = "ply\n"
        
        header += "format binary_little_endian 1.0\n"
        header += "element \(sensorType) \(numOfFrame)\n"
        header += "comment\n"
        
        switch sensorType {
        case Constants.Sensor.Imu.RotationRate.type,
             Constants.Sensor.Imu.UserAcceleration.type,
             Constants.Sensor.Imu.MagneticField.type,
             Constants.Sensor.Imu.Gravity.type:
            header += "property int64 timestamp\n"
            header += "property double x\n"
            header += "property double y\n"
            header += "property double z\n"
        case Constants.Sensor.Imu.Attitude.type:
            header += "property int64 timestamp\n"
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
    
    private func addHeaderToFile(fileUrl: URL, sensorType: String, numOfFrame: Int) {
        var header: String = "ply\n"
        
        header += "format binary_little_endian 1.0\n"
        header += "element \(sensorType) \(numOfFrame)\n"
        header += "comment\n"
        
        switch sensorType {
        case Constants.Sensor.Imu.RotationRate.type,
             Constants.Sensor.Imu.UserAcceleration.type,
             Constants.Sensor.Imu.MagneticField.type,
             Constants.Sensor.Imu.Gravity.type:
            header += "property int64 timestamp\n"
            header += "property double x\n"
            header += "property double y\n"
            header += "property double z\n"
        case Constants.Sensor.Imu.Attitude.type:
            header += "property int64 timestamp\n"
            header += "property double roll\n"
            header += "property double pitch\n"
            header += "property double yaw\n"
        default:
            print("Invalid sensor type")
            return
        }
        
        header += "end_header\n"
        
        // base on
        // https://stackoverflow.com/questions/56441768/swift-how-to-append-text-line-to-top-of-file-txt
        do {
            let fileHandle = try FileHandle(forWritingTo: fileUrl)
            fileHandle.seek(toFileOffset: 0)
            let oldData = try Data(contentsOf: fileUrl)
            var data = header.data(using: .utf8)!
            data.append(oldData)
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch {
            print("Error writing to file \(error)")
        }
    }
    
    private func generateStreamInfo() -> [ImuStreamInfo] {
        let imuFrequency = Constants.Sensor.Imu.frequency
        let imuFileEncoding = Constants.Sensor.Imu.encoding
        let rotationRateStreamInfo = ImuStreamInfo(id: "rot_1", type: Constants.Sensor.Imu.RotationRate.type, encoding: imuFileEncoding, num_frames: numberOfMeasurements, frequency: imuFrequency)
        let userAccelerationStreamInfo = ImuStreamInfo(id: "acce_1", type: Constants.Sensor.Imu.UserAcceleration.type, encoding: imuFileEncoding, num_frames: numberOfMeasurements, frequency: imuFrequency)
        let magneticFieldStreamInfo = ImuStreamInfo(id: "mag_1", type: Constants.Sensor.Imu.MagneticField.type, encoding: imuFileEncoding, num_frames: numberOfMeasurements, frequency: imuFrequency)
        let attitudeStreamInfo = ImuStreamInfo(id: "atti_1", type: Constants.Sensor.Imu.Attitude.type, encoding: imuFileEncoding, num_frames: numberOfMeasurements, frequency: imuFrequency)
        let gravityStreamInfo = ImuStreamInfo(id: "grav_1", type: Constants.Sensor.Imu.Gravity.type, encoding: imuFileEncoding, num_frames: numberOfMeasurements, frequency: imuFrequency)

        return [rotationRateStreamInfo, userAccelerationStreamInfo, magneticFieldStreamInfo, attitudeStreamInfo, gravityStreamInfo]
    }
}
