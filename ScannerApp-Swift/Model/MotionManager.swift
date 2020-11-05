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
    
    // TODO: probably no need for class variables
    private var rotationRateBinaryFileUrl: URL? = nil
    private var userAccelerationBinaryFileUrl: URL? = nil
    private var magneticFieldBinaryFileUrl: URL? = nil
    private var attitudeBinaryFileUrl: URL? = nil
    private var gravityBinaryFileUrl: URL? = nil
    
    private var rotationRateAsciiFileUrl: URL? = nil
    private var userAccelerationAsciiFileUrl: URL? = nil
    private var magneticFieldAsciiFileUrl: URL? = nil
    private var attitudeAsciiFileUrl: URL? = nil
    private var gravityAsciiFileUrl: URL? = nil
    
    private var rotationRateFileHandle: FileHandle? = nil
    private var userAccelerationFileHandle: FileHandle? = nil
    private var magneticFieldFileHandle: FileHandle? = nil
    private var attitudeFileHandle: FileHandle? = nil
    private var gravityFileHandle: FileHandle? = nil
    
    private var rotationRateAsciiFileHandle: FileHandle? = nil
    private var userAccelerationAsciiFileHandle: FileHandle? = nil
    private var magneticFieldAsciiFileHandle: FileHandle? = nil
    private var attitudeAsciiFileHandle: FileHandle? = nil
    private var gravityAsciiFileHandle: FileHandle? = nil
    
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
        FileManager.default.createFile(atPath: rotationRateBinaryFileUrl!.path, contents: nil, attributes: nil)

        let userAccelerationPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.UserAcceleration.fileExtension)!)
        userAccelerationBinaryFileUrl = URL(fileURLWithPath: userAccelerationPath)
        FileManager.default.createFile(atPath: userAccelerationBinaryFileUrl!.path, contents: nil, attributes: nil)

        let magneticFieldPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.MagneticField.fileExtension)!)
        magneticFieldBinaryFileUrl = URL(fileURLWithPath: magneticFieldPath)
        FileManager.default.createFile(atPath: magneticFieldBinaryFileUrl!.path, contents: nil, attributes: nil)

        let attitudePath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.Attitude.fileExtension)!)
        attitudeBinaryFileUrl = URL(fileURLWithPath: attitudePath)
        FileManager.default.createFile(atPath: attitudeBinaryFileUrl!.path, contents: nil, attributes: nil)

        let gravityPath = (dataPathString as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Imu.Gravity.fileExtension)!)
        gravityBinaryFileUrl = URL(fileURLWithPath: gravityPath)
        FileManager.default.createFile(atPath: gravityBinaryFileUrl!.path, contents: nil, attributes: nil)

        rotationRateFileHandle = FileHandle(forUpdatingAtPath: rotationRateBinaryFileUrl!.path)
        userAccelerationFileHandle = FileHandle(forUpdatingAtPath: userAccelerationBinaryFileUrl!.path)
        magneticFieldFileHandle = FileHandle(forUpdatingAtPath: magneticFieldBinaryFileUrl!.path)
        attitudeFileHandle = FileHandle(forUpdatingAtPath: attitudeBinaryFileUrl!.path)
        gravityFileHandle = FileHandle(forUpdatingAtPath: gravityBinaryFileUrl!.path)
        
        if isDebugMode {
            rotationRateAsciiFileUrl = URL(fileURLWithPath: (rotationRatePath as NSString).appendingPathExtension("txt")!)
            FileManager.default.createFile(atPath: rotationRateAsciiFileUrl!.path, contents: nil, attributes: nil)
            
            userAccelerationAsciiFileUrl = URL(fileURLWithPath: (userAccelerationPath as NSString).appendingPathExtension("txt")!)
            FileManager.default.createFile(atPath: userAccelerationAsciiFileUrl!.path, contents: nil, attributes: nil)
            
            magneticFieldAsciiFileUrl = URL(fileURLWithPath: (magneticFieldPath as NSString).appendingPathExtension("txt")!)
            FileManager.default.createFile(atPath: magneticFieldAsciiFileUrl!.path, contents: nil, attributes: nil)
            
            attitudeAsciiFileUrl = URL(fileURLWithPath: (attitudePath as NSString).appendingPathExtension("txt")!)
            FileManager.default.createFile(atPath: attitudeAsciiFileUrl!.path, contents: nil, attributes: nil)
            
            gravityAsciiFileUrl = URL(fileURLWithPath: (gravityPath as NSString).appendingPathExtension("txt")!)
            FileManager.default.createFile(atPath: gravityAsciiFileUrl!.path, contents: nil, attributes: nil)
            
            rotationRateAsciiFileHandle = FileHandle(forUpdatingAtPath: rotationRateAsciiFileUrl!.path)
            userAccelerationAsciiFileHandle = FileHandle(forUpdatingAtPath: userAccelerationAsciiFileUrl!.path)
            magneticFieldAsciiFileHandle = FileHandle(forUpdatingAtPath: magneticFieldAsciiFileUrl!.path)
            attitudeAsciiFileHandle = FileHandle(forUpdatingAtPath: attitudeAsciiFileUrl!.path)
            gravityAsciiFileHandle = FileHandle(forUpdatingAtPath: gravityAsciiFileUrl!.path)
        
        }
        
        self.motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: self.motionQueue) { (data, error) in
            if let validData = data {
                self.numberOfMeasurements += 1
                let motionData = MotionData(deviceMotion: validData)
//                let motionData = MotionData(deviceMotion: validData, bootTime: self.bootTime)
                
                self.writeDataBinary(motionData: motionData)

                if self.isDebugMode {

                    motionData.display()
                    
                    self.writeDataAscii(motionData: motionData)
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
        
        // TODO: extract these to functions
        if rotationRateFileHandle != nil {
            rotationRateFileHandle!.closeFile()
            rotationRateFileHandle = nil
        }
        if userAccelerationFileHandle != nil {
            userAccelerationFileHandle!.closeFile()
            userAccelerationFileHandle = nil
        }
        if magneticFieldFileHandle != nil {
            magneticFieldFileHandle!.closeFile()
            magneticFieldFileHandle = nil
        }
        if attitudeFileHandle != nil {
            attitudeFileHandle!.closeFile()
            attitudeFileHandle = nil
        }
        if gravityFileHandle != nil {
            gravityFileHandle!.closeFile()
            gravityFileHandle = nil
        }
        
        let binEncoding = Constants.EncodingCode.binary
        addHeaderToFile(fileUrl: rotationRateBinaryFileUrl!, encoding: binEncoding, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: userAccelerationBinaryFileUrl!, encoding: binEncoding, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: magneticFieldBinaryFileUrl!, encoding: binEncoding, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: attitudeBinaryFileUrl!, encoding: binEncoding, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrames: numberOfMeasurements)
        addHeaderToFile(fileUrl: gravityBinaryFileUrl!, encoding: binEncoding, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrames: numberOfMeasurements)
        
        if isDebugMode {
            
            if rotationRateAsciiFileHandle != nil {
                rotationRateAsciiFileHandle!.closeFile()
                rotationRateAsciiFileHandle = nil
            }
            if userAccelerationAsciiFileHandle != nil {
                userAccelerationAsciiFileHandle!.closeFile()
                userAccelerationAsciiFileHandle = nil
            }
            if magneticFieldAsciiFileHandle != nil {
                magneticFieldAsciiFileHandle!.closeFile()
                magneticFieldAsciiFileHandle = nil
            }
            if attitudeAsciiFileHandle != nil {
                attitudeAsciiFileHandle!.closeFile()
                attitudeAsciiFileHandle = nil
            }
            if gravityAsciiFileHandle != nil {
                gravityAsciiFileHandle!.closeFile()
                gravityAsciiFileHandle = nil
            }
            
            let asciiEncoding = Constants.EncodingCode.ascii
            addHeaderToFile(fileUrl: rotationRateAsciiFileUrl!, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.RotationRate.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: userAccelerationAsciiFileUrl!, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.UserAcceleration.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: magneticFieldAsciiFileUrl!, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.MagneticField.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: attitudeAsciiFileUrl!, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.Attitude.type, numOfFrames: numberOfMeasurements)
            addHeaderToFile(fileUrl: gravityAsciiFileUrl!, encoding: asciiEncoding, sensorType: Constants.Sensor.Imu.Gravity.type, numOfFrames: numberOfMeasurements)
        }
        
    }
    
    private func writeDataBinary(motionData: MotionData) {
        rotationRateFileHandle?.write(motionData.getRotationRateDataBinary())
        userAccelerationFileHandle?.write(motionData.getUserAccelerationDataBinary())
        magneticFieldFileHandle?.write(motionData.getMagneticFieldDataBinary())
        attitudeFileHandle?.write(motionData.getAttitudeDataBinary())
        gravityFileHandle?.write(motionData.getGravityDataBinary())
    }
    
    private func writeDataAscii(motionData: MotionData) {
        rotationRateAsciiFileHandle?.write(motionData.getRotationRateDataAscii())
        userAccelerationAsciiFileHandle?.write(motionData.getUserAccelerationDataAscii())
        magneticFieldAsciiFileHandle?.write(motionData.getMagneticFieldDataAscii())
        attitudeAsciiFileHandle?.write(motionData.getAttitudeDataAscii())
        gravityAsciiFileHandle?.write(motionData.getGravityDataAscii())
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
