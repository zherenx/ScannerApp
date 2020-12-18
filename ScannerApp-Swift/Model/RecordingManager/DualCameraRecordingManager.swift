//
//  DualCameraRecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-12-11.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation
import CoreLocation

@available(iOS 13.0, *)
class DualCameraRecordingManager: NSObject {
    
    private let session = AVCaptureMultiCamSession()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let motionManager = MotionManager()
    
//    private let dataOutputQueue = DispatchQueue(label: "data output queue")

//    private var isRecording = false
    
    private var dirUrl: URL!
    private var recordingId: String!
    private var mainVideoFilePath: String!
    private var secondaryVideoFilePath: String!
    
    private let locationManager = CLLocationManager()
    private var gpsLocation: [Double] = []
    
    private var extrinsics: Data?
    
    private var mainCameraInput: AVCaptureDeviceInput?
    private let mainCameraOutput = AVCaptureMovieFileOutput()
    
    private var secondaryCameraInput: AVCaptureDeviceInput?
    private let secondaryCameraOutput = AVCaptureMovieFileOutput()
    
    private var username: String?
    private var sceneDescription: String?
    private var sceneType: String?
    
    private var mainVideoRecordingFinished = false
    private var secondaryVideoRecordingFinished = false
    
    private var mainCameraResolution: [Int] = []
    private var mainCameraIntrinsicArray: [Float] = []
    private var mainCameraFramerate: Int = -1
    
    private var secondaryCameraResolution: [Int] = []
    private var secondaryCameraIntrinsicArray: [Float] = []
    private var secondaryCameraFramerate: Int = -1
    
    override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        
        sessionQueue.async {
            self.configureSession()
            
            self.session.startRunning()
        }
    }
    
    deinit {
        sessionQueue.sync {
            self.session.stopRunning()
        }
    }
    
    private func configureSession() {
        
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // Get devices
        guard let mainCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the wide angle camera")
            return
        }
        
        var secondaryCameraDevice: AVCaptureDevice
        
        if let ultrawideCameraDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            secondaryCameraDevice = ultrawideCameraDevice
        } else if let telephotoCameraDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
            secondaryCameraDevice = telephotoCameraDevice
        } else {
            print("Could not find either ultrawide or telephone camera")
            return
        }
        
//        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: nil, position: .back), let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: nil, position: .back) {
//            self.extrinsics = AVCaptureDevice.extrinsicMatrix(from: tele, to: wide)
//
//            let matrix: matrix_float4x3 = self.extrinsics!.withUnsafeBytes { $0.pointee }
//
//            print(matrix)
//        }
        
        
        // Add input
        do {
            mainCameraInput = try AVCaptureDeviceInput(device: mainCameraDevice)
            
            guard let mainCameraInput = mainCameraInput, session.canAddInput(mainCameraInput) else {
                print("Could not add wide angle camera device input")
                return
            }
            
            session.addInputWithNoConnections(mainCameraInput)
        } catch {
            print("Couldn't create wide angle camera device input: \(error)")
            return
        }
        
        do {
            secondaryCameraInput = try AVCaptureDeviceInput(device: secondaryCameraDevice)
            
            guard let secondaryCameraInput = secondaryCameraInput, session.canAddInput(secondaryCameraInput) else {
                print("Could not add secondary camera device input")
                return
            }
            
            session.addInputWithNoConnections(secondaryCameraInput)
        } catch {
            print("Couldn't create secondary camera device input: \(error)")
            return
        }

        // Add output
        guard session.canAddOutput(mainCameraOutput) else {
            print("Could not add wide-angle camera output")
            return
        }
        session.addOutputWithNoConnections(mainCameraOutput)
        
        guard session.canAddOutput(secondaryCameraOutput) else {
            print("Could not add secondary camera output")
            return
        }
        session.addOutputWithNoConnections(secondaryCameraOutput)
        
        // Setup input/output connection
        guard let mainCameraPort = mainCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: mainCameraDevice.position).first
        else {
                print("Could not obtain wide angle camera input ports")
                return
        }
        
        let secondaryCameraPort: AVCaptureInput.Port
        
        if secondaryCameraDevice.deviceType == .builtInUltraWideCamera {
            secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
                                                              sourceDeviceType: .builtInUltraWideCamera,
                                                              sourceDevicePosition: secondaryCameraDevice.position).first!
        } else if secondaryCameraDevice.deviceType == .builtInTelephotoCamera {
            secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
                                                              sourceDeviceType: .builtInTelephotoCamera,
                                                              sourceDevicePosition: secondaryCameraDevice.position).first!
        } else {
            print("Could not obtain secondary camera input ports")
            return
        }
        
        let mainCameraConnection = AVCaptureConnection(inputPorts: [mainCameraPort], output: mainCameraOutput)
        guard session.canAddConnection(mainCameraConnection) else {
            print("Cannot add wide-angle input to output")
            return
        }
        session.addConnection(mainCameraConnection)
        mainCameraConnection.videoOrientation = .landscapeRight
        
        let mainCameraAvailableVideoCodecTypes = mainCameraOutput.availableVideoCodecTypes
        if mainCameraAvailableVideoCodecTypes.contains(.h264) {
            mainCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: mainCameraConnection)
        }
        
        let secondaryCameraConnection = AVCaptureConnection(inputPorts: [secondaryCameraPort], output: secondaryCameraOutput)
        guard session.canAddConnection(secondaryCameraConnection) else {
            print("Cannot add secondary input to output")
            return
        }
        session.addConnection(secondaryCameraConnection)
        secondaryCameraConnection.videoOrientation = .landscapeRight
        
        let secondaryCameraAvailableVideoCodecTypes = secondaryCameraOutput.availableVideoCodecTypes
        if secondaryCameraAvailableVideoCodecTypes.contains(.h264) {
            secondaryCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: secondaryCameraConnection)
        }
        
        configureVideoQuality()
        
    }
    
    private func configureVideoQuality() {
        
        // Set to highest first
        for format in mainCameraInput!.device.formats.reversed() {
            if format.isMultiCamSupported {

                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
//                print("main, width: \(dims.width), height: \(dims.height)")
                
                let framerate = format.videoSupportedFrameRateRanges[0]
//                print("main, width: \(dims.width), height: \(dims.height), framerate: \(framerate.maxFrameRate)")
                
                if framerate.maxFrameRate < 60.0 {
                    continue
                }

                do {
                    try mainCameraInput?.device.lockForConfiguration()
                    mainCameraInput?.device.activeFormat = format
                    mainCameraInput?.device.unlockForConfiguration()
                } catch {
                    print("Could not lock main camera device for configuration: \(error)")
                }
                
                print("main, width: \(dims.width), height: \(dims.height), framerate: \(framerate.maxFrameRate)")

                break
            }
        }

        for format in secondaryCameraInput!.device.formats.reversed() {
            if format.isMultiCamSupported {

                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
//                print("secondary, width: \(dims.width), height: \(dims.height)")
                
                let framerate = format.videoSupportedFrameRateRanges[0]
//                print("secondary, width: \(dims.width), height: \(dims.height), framerate: \(framerate.maxFrameRate)")

                if framerate.maxFrameRate < 60.0 {
                    continue
                }
                
                do {
                    try secondaryCameraInput?.device.lockForConfiguration()
                    secondaryCameraInput?.device.activeFormat = format
                    secondaryCameraInput?.device.unlockForConfiguration()
                } catch {
                    print("Could not lock main camera device for configuration: \(error)")
                }

                print("secondary, width: \(dims.width), height: \(dims.height), framerate: \(framerate.maxFrameRate)")
                
                break
            }
        }
        
        // reduce video quality if needed
        while true {

            if session.hardwareCost <= 1.0 && session.systemPressureCost <= 1.0 {
                break
            }

            reduceResolution()
            
            if session.hardwareCost <= 1.0 && session.systemPressureCost <= 1.0 {
                break
            }
            
            reduceFramerate()
            
        }
        
    }

    private func reduceResolution() {

        let mainCameraDims = CMVideoFormatDescriptionGetDimensions(mainCameraInput!.device.activeFormat.formatDescription)
        let activeWidthMain = mainCameraDims.width
        let activeHeightMain = mainCameraDims.height
        
        let secondaryCameraDims = CMVideoFormatDescriptionGetDimensions(secondaryCameraInput!.device.activeFormat.formatDescription)
        let activeWidthSecondary = secondaryCameraDims.width
        let activeHeightSecondary = secondaryCameraDims.height
        
        if activeWidthMain > activeWidthSecondary || activeHeightMain > activeHeightSecondary {
            print("reducing main resolution")
            reduceResolution(device: mainCameraInput!.device)
            
            do {
                try secondaryCameraInput!.device.lockForConfiguration()
                secondaryCameraInput!.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: 60)
                secondaryCameraInput!.device.unlockForConfiguration()
                print("secondary, framerate reset to 60")
            } catch {
                print("Could not lock secondary camera device for configuration: \(error)")
            }
            
        } else {
            print("reducing secondary resolution")
            reduceResolution(device: secondaryCameraInput!.device)
            
            do {
                try mainCameraInput!.device.lockForConfiguration()
                mainCameraInput!.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: 60)
                mainCameraInput!.device.unlockForConfiguration()
                print("main, framerate reset to 60")
            } catch {
                print("Could not lock main camera device for configuration: \(error)")
            }
        }

    }
    
    private func reduceResolution(device: AVCaptureDevice) {
        
        let activeFormat = device.activeFormat
        
        let activeDims = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
        let activeWidth = activeDims.width
        let activeHeight = activeDims.height
        
        let formats = device.formats
        if let formatIndex = formats.firstIndex(of: activeFormat) {
            
            for index in (0..<formatIndex).reversed() {
                
                let format = device.formats[index]
                
                let framerate = format.videoSupportedFrameRateRanges[0]
                
                if format.isMultiCamSupported && framerate.maxFrameRate >= 60.0 {
                    
                    let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    let width = dims.width
                    let height = dims.height
                    
                    if width < activeWidth || height < activeHeight {
                        do {
                            try device.lockForConfiguration()
                            device.activeFormat = format
                            device.unlockForConfiguration()
                            
                            print("width \(activeWidth) -> \(width), height \(activeHeight) -> \(height)")
                            
                        } catch {
                            print("Could not lock device for configuration: \(error)")
                        }
                        
                    }
                }
            }
        }
        
    }
    
    private func reduceFramerate() {
        
        print("reducing framerate")
        
        let mainCameraMinFrameDuration = mainCameraInput!.device.activeVideoMinFrameDuration
        let mainCameraActiveMaxFramerate: Double = Double(mainCameraMinFrameDuration.timescale) / Double(mainCameraMinFrameDuration.value)
        
        let secondaryCameraMinFrameDuration = secondaryCameraInput!.device.activeVideoMinFrameDuration
        let secondaryCameraActiveMaxFramerate: Double = Double(secondaryCameraMinFrameDuration.timescale) / Double(secondaryCameraMinFrameDuration.value)
        
        var targetFramerate = mainCameraActiveMaxFramerate
        if mainCameraActiveMaxFramerate > 60.0 || secondaryCameraActiveMaxFramerate > 60.0 {
            targetFramerate = 60.0
        } else if mainCameraActiveMaxFramerate > 45.0 || secondaryCameraActiveMaxFramerate > 45.0 {
            targetFramerate = 45.0
        } else if mainCameraActiveMaxFramerate > 30.0 || secondaryCameraActiveMaxFramerate > 30.0 {
            targetFramerate = 30.0
        } else {
            return
        }
        
        do {
            try mainCameraInput!.device.lockForConfiguration()
            mainCameraInput!.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: Int32(targetFramerate))
            mainCameraInput!.device.unlockForConfiguration()
            
            print("main, framerate \(mainCameraActiveMaxFramerate) -> \(targetFramerate)")
            
        } catch {
            print("Could not lock main camera device for configuration: \(error)")
        }
        
        do {
            try secondaryCameraInput!.device.lockForConfiguration()
            secondaryCameraInput!.videoMinFrameDurationOverride = CMTimeMake(value: 1, timescale: Int32(targetFramerate))
            secondaryCameraInput!.device.unlockForConfiguration()
            
            print("secondary, framerate \(secondaryCameraActiveMaxFramerate) -> \(targetFramerate)")
            
        } catch {
            print("Could not lock secondary camera device for configuration: \(error)")
        }
        
    }
    
}

@available(iOS 13.0, *)
extension DualCameraRecordingManager: RecordingManager {
    
    var isRecording: Bool {
        
        // TODO: Should these be check in the session queue??
        if mainCameraOutput.isRecording && secondaryCameraOutput.isRecording {
            return true
        } else if !mainCameraOutput.isRecording && !secondaryCameraOutput.isRecording {
            return false
        } else {
            print("MultiCam session is at unexpected state")
            
            if mainCameraOutput.isRecording {
                mainCameraOutput.stopRecording()
            }
            if secondaryCameraOutput.isRecording {
                secondaryCameraOutput.stopRecording()
            }
            return true
        }
    }
    
    func getSession() -> NSObject {
        
        while session.inputs.count < 2 {
            print("...")
            usleep(1000)
        }

        return session
    }
    
    func startRecording(username: String, sceneDescription: String, sceneType: String) {
        
        sessionQueue.async { [self] in
            
            self.username = username
            self.sceneDescription = sceneDescription
            self.sceneType = sceneType
            
            mainVideoRecordingFinished = false
            secondaryVideoRecordingFinished = false
            
            gpsLocation = Helper.getGpsLocation(locationManager: locationManager)
            
            recordingId = Helper.getRecordingId()
            dirUrl = URL(fileURLWithPath: Helper.getRecordingDataDirectoryPath(recordingId: recordingId))
            
            // Motion data
            motionManager.startRecording(dataPathString: dirUrl.path, recordingId: recordingId)
            
            // Video
            let mainVideoFilename = recordingId + "-main"
            mainVideoFilePath = (dirUrl.path as NSString).appendingPathComponent((mainVideoFilename as NSString).appendingPathExtension("mp4")!)
            
            let secondaryVideoFilename = recordingId + "-secondary"
            secondaryVideoFilePath = (dirUrl.path as NSString).appendingPathComponent((secondaryVideoFilename as NSString).appendingPathExtension("mp4")!)
            
            self.mainCameraOutput.startRecording(to: URL(fileURLWithPath: mainVideoFilePath), recordingDelegate: self)
            self.secondaryCameraOutput.startRecording(to: URL(fileURLWithPath: secondaryVideoFilePath), recordingDelegate: self)
    
        }

    }
    
    func stopRecording() {
        
        sessionQueue.async {
            self.mainCameraOutput.stopRecording()
            self.secondaryCameraOutput.stopRecording()
        }
        
    }

}

@available(iOS 13.0, *)
extension DualCameraRecordingManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
        }

        sessionQueue.async { [self] in
            
            if outputFileURL.path == mainVideoFilePath {
                mainVideoRecordingFinished = true
                print("main video ready")
            } else if outputFileURL.path == secondaryVideoFilePath {
                secondaryVideoRecordingFinished = true
                print("secondary video ready")
            }
            
            if mainVideoRecordingFinished && secondaryVideoRecordingFinished {
                
                var streamInfo: [StreamInfo] = motionManager.stopRecordingAndReturnStreamInfo()

                let mainVideoNumberOfFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: mainVideoFilePath))
                let mainCameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: "color_camera", encoding: "h264", frequency: mainCameraFramerate, numberOfFrames: mainVideoNumberOfFrames, fileExtension: "mp4", resolution: mainCameraResolution, intrinsics: mainCameraIntrinsicArray, extrinsics: nil)
                streamInfo.append(mainCameraStreamInfo)
                
                let secondaryVideoNumberOfFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: secondaryVideoFilePath))
                let secondaryCameraStreamInfo = CameraStreamInfo(id: "color_back_2", type: "color_camera", encoding: "h264", frequency: secondaryCameraFramerate, numberOfFrames: secondaryVideoNumberOfFrames, fileExtension: "mp4", resolution: secondaryCameraResolution, intrinsics: secondaryCameraIntrinsicArray, extrinsics: nil)
                streamInfo.append(secondaryCameraStreamInfo)

                let metadata = Metadata(username: username ?? "", userInputDescription: sceneDescription ?? "", sceneType: sceneType ?? "", gpsLocation: gpsLocation, streams: streamInfo, numberOfFiles: 7)

                let metadataPath = (dirUrl.path as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension("json")!)

                metadata.display()
                metadata.writeToFile(filepath: metadataPath)

                username = nil
                sceneDescription = nil
                sceneType = nil
            }

        }
    }
    
    
}
