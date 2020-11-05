//
//  MotionManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-03-19.
//  Copyright © 2020 jx16. All rights reserved.
//

import CoreMotion

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
    private var isDebugMode: Bool = false
    
    private var rotationRateBinaryFileUrl: URL!
    private var userAccelerationBinaryFileUrl: URL!
    private var magneticFieldBinaryFileUrl: URL!
    private var attitudeBinaryFileUrl: URL!
    private var gravityBinaryFileUrl: URL!
    
    private var rotationRateAsciiFileUrl: URL!
    private var userAccelerationAsciiFileUrl: URL!
    private var magneticFieldAsciiFileUrl: URL!
    private var attitudeAsciiFileUrl: URL!
    private var gravityAsciiFileUrl: URL!
    
    private init() {
        motionManager.deviceMotionUpdateInterval = 1.0 / Double(Constants.Sensor.Imu.frequency)
        motionQueue.maxConcurrentOperationCount = 1
        
        // we can use this if we want the real time instead of system up time
//        bootTime = Helper.bootTime()!
    }
    
    func startRecording(dataPathString: String, recordingId: String) {
        if isRecording {
            // TODO: do something
            return
        }
        
        isRecording = true // should i move this to later?
        numberOfMeasurements = 0
        isDebugMode = UserDefaults.debugFlag
        
        let rotationRatePath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.RotationRate.fileExtension)!)
        rotationRateBinaryFileUrl = URL(fileURLWithPath: rotationRatePath)
        createEmptyFile(fileUrl: rotationRateBinaryFileUrl)

        let userAccelerationPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.UserAcceleration.fileExtension)!)
        userAccelerationBinaryFileUrl = URL(fileURLWithPath: userAccelerationPath)
        createEmptyFile(fileUrl: userAccelerationBinaryFileUrl)

        let magneticFieldPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.MagneticField.fileExtension)!)
        magneticFieldBinaryFileUrl = URL(fileURLWithPath: magneticFieldPath)
        createEmptyFile(fileUrl: magneticFieldBinaryFileUrl)

        let attitudePath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.Attitude.fileExtension)!)
        attitudeBinaryFileUrl = URL(fileURLWithPath: attitudePath)
        createEmptyFile(fileUrl: attitudeBinaryFileUrl)

        let gravityPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.Gravity.fileExtension)!)
        gravityBinaryFileUrl = URL(fileURLWithPath: gravityPath)
        createEmptyFile(fileUrl: gravityBinaryFileUrl)
        
        if isDebugMode {
            rotationRateAsciiFileUrl = URL(fileURLWithPath: (rotationRatePath as NSString).appendingPathExtension("txt")!)
            createEmptyFile(fileUrl: rotationRateAsciiFileUrl)
            
            userAccelerationAsciiFileUrl = URL(fileURLWithPath: (userAccelerationPath as NSString).appendingPathExtension("txt")!)
            createEmptyFile(fileUrl: userAccelerationAsciiFileUrl)
            
            magneticFieldAsciiFileUrl = URL(fileURLWithPath: (magneticFieldPath as NSString).appendingPathExtension("txt")!)
            createEmptyFile(fileUrl: magneticFieldAsciiFileUrl)
            
            attitudeAsciiFileUrl = URL(fileURLWithPath: (attitudePath as NSString).appendingPathExtension("txt")!)
            createEmptyFile(fileUrl: attitudeAsciiFileUrl)
            
            gravityAsciiFileUrl = URL(fileURLWithPath: (gravityPath as NSString).appendingPathExtension("txt")!)
            createEmptyFile(fileUrl: gravityAsciiFileUrl)
        }
        
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: self.motionQueue) { (data, error) in
            if let validData = data {
                self.numberOfMeasurements += 1
                let motionData = MotionData(deviceMotion: validData)
//                let motionData = MotionData(deviceMotion: validData, bootTime: self.bootTime)

                motionData.writeToFileInBinaryFormat(rotationRateFileUrl: self.rotationRateBinaryFileUrl, userAccelerationFileUrl: self.userAccelerationBinaryFileUrl, magneticFieldFileUrl: self.magneticFieldBinaryFileUrl, attitudeFileUrl: self.attitudeBinaryFileUrl, gravityFileUrl: self.gravityBinaryFileUrl)

                if self.isDebugMode {

                    motionData.display()

                    motionData.writeToFileInAsciiFormat(rotationRateFileUrl: self.rotationRateAsciiFileUrl, userAccelerationFileUrl: self.userAccelerationAsciiFileUrl, magneticFieldFileUrl: self.magneticFieldAsciiFileUrl, attitudeFileUrl: self.attitudeAsciiFileUrl, gravityFileUrl: self.gravityAsciiFileUrl)
                }

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
        
        let binEncoding = Constants.EncodingCode.binary
        addHeaderToFile(fileUrl: rotationRateBinaryFileUrl, encoding: binEncoding, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: userAccelerationBinaryFileUrl, encoding: binEncoding, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: magneticFieldBinaryFileUrl, encoding: binEncoding, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: attitudeBinaryFileUrl, encoding: binEncoding, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: gravityBinaryFileUrl, encoding: binEncoding, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrames: numberOfMeasurements)
        
        if isDebugMode {
            let asciiEncoding = Constants.EncodingCode.ascii
            addHeaderToFile(fileUrl: rotationRateAsciiFileUrl, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: userAccelerationAsciiFileUrl, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: magneticFieldAsciiFileUrl, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: attitudeAsciiFileUrl, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: gravityAsciiFileUrl, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrames: numberOfMeasurements)
        }
        
    }
    
    private func createEmptyFile(fileUrl: URL) {
        do {
            try "".write(to: fileUrl, atomically: true, encoding: .utf8)
        } catch {
            print("fail to create file at \(fileUrl.absoluteString)")
            print(error)
        }
    }
    
    private func writeImuHeader(fileUrl: URL, encoding: String, sensorType: String, numOfFrame: Int) {
        var header: String = "ply\n"
        
        switch encoding {
        case Constants.EncodingCode.binary:
            header += "format binary_little_endian 1.0\n"
        case Constants.EncodingCode.ascii:
            header += "format ascii 1.0\n"
        default:
            print("Invalid encoding")
        }
        
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
    
    private func addHeaderToFile(fileUrl: URL, encoding: String, sensorType: String, numOfFrames: Int) {
        var header: String = "ply\n"

        switch encoding {
        case Constants.EncodingCode.binary:
            header += "format binary_little_endian 1.0\n"
        case Constants.EncodingCode.ascii:
            header += "format ascii 1.0\n"
        default:
            print("Invalid encoding")
        }
        
        header += "element \(sensorType) \(numOfFrames)\n"
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
        let imuFileEncoding = Constants.EncodingCode.binary
        let rotationRateStreamInfo = ImuStreamInfo(id: "rot_1", type: Constants.Sensor.Imu.RotationRate.type, encoding: imuFileEncoding, frequency: imuFrequency, numberOfFrames: numberOfMeasurements, fileExtension: Constants.Sensor.Imu.RotationRate.fileExtension)
        let userAccelerationStreamInfo = ImuStreamInfo(id: "acce_1", type: Constants.Sensor.Imu.UserAcceleration.type, encoding: imuFileEncoding, frequency: imuFrequency, numberOfFrames: numberOfMeasurements, fileExtension: Constants.Sensor.Imu.UserAcceleration.fileExtension)
        let magneticFieldStreamInfo = ImuStreamInfo(id: "mag_1", type: Constants.Sensor.Imu.MagneticField.type, encoding: imuFileEncoding, frequency: imuFrequency, numberOfFrames: numberOfMeasurements, fileExtension: Constants.Sensor.Imu.MagneticField.fileExtension)
        let attitudeStreamInfo = ImuStreamInfo(id: "atti_1", type: Constants.Sensor.Imu.Attitude.type, encoding: imuFileEncoding, frequency: imuFrequency, numberOfFrames: numberOfMeasurements, fileExtension: Constants.Sensor.Imu.Attitude.fileExtension)
        let gravityStreamInfo = ImuStreamInfo(id: "grav_1", type: Constants.Sensor.Imu.Gravity.type, encoding: imuFileEncoding, frequency: imuFrequency, numberOfFrames: numberOfMeasurements, fileExtension: Constants.Sensor.Imu.Gravity.fileExtension)

        return [rotationRateStreamInfo, userAccelerationStreamInfo, magneticFieldStreamInfo, attitudeStreamInfo, gravityStreamInfo]
    }
}
