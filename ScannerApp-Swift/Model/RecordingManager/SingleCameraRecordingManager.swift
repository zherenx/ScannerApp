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
    
//    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
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
    
    // TODO: this need to be tested
//    deinit {
//        sessionQueue.async {
//            self.session.stopRunning()
//        }
//    }
    
    private func configureSession() {
        
        self.session.beginConfiguration()
        
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

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
            } else {
                print("Couldn't add video device input to the session.")
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            self.session.commitConfiguration()
            return
        }
        
        if self.session.canAddOutput(self.movieFileOutput) {
            self.session.addOutput(self.movieFileOutput)
            
//            self.session.sessionPreset = .photo
            self.session.sessionPreset = .hd1920x1080

            if let connection = self.movieFileOutput.connection(with: .video) {
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
        
        self.session.commitConfiguration()
        
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
            
//            if UIDevice.current.isMultitaskingSupported {
//                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
//            }
            
            gpsLocation = Helper.getGpsLocation(locationManager: locationManager)
            
            let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
            
            movieFileOutputConnection?.videoOrientation = .landscapeRight
            
            self.recordingId = Helper.getRecordingId()
            
            let recordingDataDirectoryPath = Helper.getRecordingDataDirectoryPath(recordingId: self.recordingId)
            
            // save metadata path, it will be used when recording is finished
            self.metadataPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((self.recordingId as NSString).appendingPathExtension("json")!)
            
            // TODO:
            // Camera data
            
            // Motion data
            self.motionManager.startRecording(dataPathString: recordingDataDirectoryPath, recordingId: self.recordingId)
            
            // Video
            self.movieFilePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((self.recordingId as NSString).appendingPathExtension(Constants.Sensor.Camera.fileExtension)!)
            self.movieFileOutput.startRecording(to: URL(fileURLWithPath: self.movieFilePath), recordingDelegate: self)
        
            isRecording = true
        }
        
    }
    
    func stopRecording() {
        
        sessionQueue.async { [self] in
            
            self.movieFileOutput.stopRecording()
            
            var streamInfo: [StreamInfo] = self.motionManager.stopRecordingAndReturnStreamInfo()
            
            while !self.videoIsReady {
                // this is a heck
                // wait until video is ready
                print("waiting for video ...")
                usleep(10000)
            }
            // get number of frames when video is ready
            let numColorFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: self.movieFilePath))
            
            let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, numberOfFrames: numColorFrames, fileExtension: "mp4", resolution: self.colorResolution, intrinsics: self.cameraIntrinsicArray, extrinsics: nil)
            
            streamInfo.append(cameraStreamInfo)
            
            let metadata = Metadata(username: username ?? "", userInputDescription: sceneDescription ?? "", sceneType: sceneType ?? "", gpsLocation: self.gpsLocation, streams: streamInfo, numberOfFiles: 7)
            
            metadata.display()
            metadata.writeToFile(filepath: self.metadataPath)
            
            self.videoIsReady = false
            isRecording = false
        }
        
    }
    
}

extension SingleCameraRecordingManager: AVCaptureFileOutputRecordingDelegate {
    
//    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
//        // Enable the Record button to let the user stop recording.
//        DispatchQueue.main.async {
//            self.popUpView.isHidden = true
//
//            self.recordButton.setTitle("Stop", for: .normal)
//            self.recordButton.backgroundColor = .systemRed
//            self.recordButton.isEnabled = true
//        }
//    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

//        func cleanup() {
//
//            if let currentBackgroundRecordingID = backgroundRecordingID {
//                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
//
//                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
//                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
//                }
//            }
//        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
//        cleanup()
        
//        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
//        DispatchQueue.main.async {
//            self.recordButton.setTitle("Record", for: .normal)
//            self.recordButton.backgroundColor = .systemBlue
//            self.recordButton.isEnabled = true
//        }
        
        videoIsReady = true
    }
}
