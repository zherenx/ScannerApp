//
//  SingleCameraRecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-18.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation
import CoreLocation

class SingleCameraRecordingManager: NSObject {
    
    private let sessionQueue = DispatchQueue(label: "single camera recording queue")
    
    private let session = AVCaptureSession()

    private let motionManager = MotionManager()
    
//    private var dirUrl: URL!
    private var recordingId: String!
    private var movieFilePath: String!
    private var metadataPath: String!
    var isRecording: Bool = false
    
    private var videoIsReady: Bool = false // this is a heck, consider improve it
    
    private var defaultVideoDevice: AVCaptureDevice?

    private let movieFileOutput = AVCaptureMovieFileOutput()
    
    private let locationManager = CLLocationManager()
    private var gpsLocation: [Double] = []
    
    private var colorResolution: [Int] = []
    private var cameraIntrinsicArray: [Float]?
    
    private var username: String?
    private var sceneDescription: String?
    private var sceneType: String?
    
    override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        
        sessionQueue.async {
            self.configureSession()
            
            self.session.startRunning()
        }
    }
    
    // TODO: session.stopRunning need to be called at some point, but called in deinit cause error
//    deinit {
//        sessionQueue.async {
//            self.session.stopRunning()
//        }
//    }
    
    private func configureSession() {
        
        session.beginConfiguration()
        
        do {
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                return
            }
            
            do {
                try videoDevice.lockForConfiguration()
                
                let targetFrameDuration = CMTimeMake(value: 1, timescale: Int32(Constants.Sensor.Camera.frequency))
                videoDevice.activeVideoMaxFrameDuration = targetFrameDuration
                videoDevice.activeVideoMinFrameDuration = targetFrameDuration
                
                videoDevice.unlockForConfiguration()
            } catch {
                print("Error configurating video device")
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            } else {
                print("Couldn't add video device input to the session.")
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(movieFileOutput) {
            session.addOutput(movieFileOutput)
            
//            session.sessionPreset = .photo
            session.sessionPreset = .hd1920x1080

            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                
                connection.videoOrientation = .landscapeRight
            }
        }
        
        let videoFormatDescription = defaultVideoDevice!.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription)
        
        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        colorResolution = [height, width]
        
        let fov = defaultVideoDevice!.activeFormat.videoFieldOfView
        let aspect = Float(width) / Float(height)
        let t = tan((0.5 * fov) * Float.pi / 180)
        
        let fx = 0.5 * Float(width) / t
//        let fy = 0.5 * Float(height) / t
        let fy = fx
        
        let mx = Float(width - 1) / 2.0
        let my = Float(height - 1) / 2.0
        
        cameraIntrinsicArray = [fx, 0.0, 0.0, 0.0, fy, 0.0, mx, my, 1.0]
        
        session.commitConfiguration()
        
    }

}

extension SingleCameraRecordingManager: RecordingManager {
    
    // TODO: test this
//    var isRecording: Bool {
//        return movieFileOutput.isRecording
//    }
    
    func getSession() -> NSObject {
        return session
    }
    
    func startRecording(username: String, sceneDescription: String, sceneType: String) {
        
        sessionQueue.async { [self] in
            
            self.username = username
            self.sceneDescription = sceneDescription
            self.sceneType = sceneType
            
            gpsLocation = Helper.getGpsLocation(locationManager: locationManager)
            
            let movieFileOutputConnection = movieFileOutput.connection(with: .video)
            
            movieFileOutputConnection?.videoOrientation = .landscapeRight
            
            recordingId = Helper.getRecordingId()
            
            let recordingDataDirectoryPath = Helper.getRecordingDataDirectoryPath(recordingId: recordingId)
            
            // save metadata path, it will be used when recording is finished
            metadataPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension("json")!)
            
            // TODO:
            // Camera data
            
            // Motion data
            motionManager.startRecording(dataPathString: recordingDataDirectoryPath, recordingId: recordingId)
            
            // Video
            movieFilePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Camera.fileExtension)!)
            movieFileOutput.startRecording(to: URL(fileURLWithPath: movieFilePath), recordingDelegate: self)
        
            isRecording = true
        }
        
    }
    
    func stopRecording() {
        
        sessionQueue.async { [self] in
            
            movieFileOutput.stopRecording()
            
            var streamInfo: [StreamInfo] = motionManager.stopRecordingAndReturnStreamInfo()
            
            while !videoIsReady {
                // this is a heck
                // wait until video is ready
                print("waiting for video ...")
                usleep(10000)
            }
            // get number of frames when video is ready
            let numColorFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: movieFilePath))
            
            let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, numberOfFrames: numColorFrames, fileExtension: "mp4", resolution: colorResolution, intrinsics: cameraIntrinsicArray, extrinsics: nil)
            
            streamInfo.append(cameraStreamInfo)
            
            let metadata = Metadata(username: username ?? "", userInputDescription: sceneDescription ?? "", sceneType: sceneType ?? "", gpsLocation: gpsLocation, streams: streamInfo, numberOfFiles: 7)
            
            metadata.display()
            metadata.writeToFile(filepath: metadataPath)
            
            videoIsReady = false
            isRecording = false
        }
        
    }
    
}

extension SingleCameraRecordingManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
        }
        
        // TODO: see if have better way
        videoIsReady = true
    }
}
