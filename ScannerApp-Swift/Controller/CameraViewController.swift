//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import CoreLocation
import CoreMotion
import UIKit

class CameraViewController: UIViewController, CameraViewControllerPopUpViewDelegate {
    
    private let locationManager = CLLocationManager()
    private let motionManager = MotionManager()
    
    private var gpsLocation: [Double]!
    private var colorResolution: [Int]!
    private var cameraIntrinsicArray: [Float]?
    
    private var recordingId: String!
    private var movieFilePath: String!
    private var metadataPath: String!
    
    private var videoIsReady: Bool = false // this is a heck, consider improve it
    
    private let session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private var defaultVideoDevice: AVCaptureDevice?

    private let movieFileOutput = AVCaptureMovieFileOutput()
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var recordButton: UIButton!
    
    var popUpView: PopUpView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        self.previewView.videoPreviewLayer.session = self.session
        
        // TODO: order of these function calls might matter, consider improve on this
        self.configurateSession()
        
        gpsLocation = [] // Do we want to enforce valid gps location?
        updateGpsLocation()
        
        self.setupPopUpView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.sessionQueue.async {
            self.session.stopRunning()
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func setupPopUpView() {
        
        popUpView = PopUpView()
        popUpView.delegate = self
        
        view.addSubview(popUpView)
        
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popUpView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
        
    }

    private func configurateSession() {
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
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
        
        DispatchQueue.main.async {
            self.recordButton.isEnabled = false
        }
        
        if !self.movieFileOutput.isRecording {
            
            self.updateGpsLocation()
            
            DispatchQueue.main.async {
                self.popUpView.isHidden = false
            }
            
        } else {
            self.stopRecording()
        }

    }
    
    func dismissPopUpView() {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            self.recordButton.isEnabled = true
        }
    }
    
    func startRecording() {
        
        sessionQueue.async {
            
            if UIDevice.current.isMultitaskingSupported {
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
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
        }
    }
    
    private func stopRecording() {
        sessionQueue.async {
            
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
            
            let username = self.popUpView.firstName + " " + self.popUpView.lastName
            let sceneDescription = self.popUpView.userInputDescription
            let sceneType = self.popUpView.sceneTypes[self.popUpView.sceneTypeIndex]
            let metadata = Metadata(username: username, userInputDescription: sceneDescription, sceneType: sceneType, gpsLocation: self.gpsLocation, streams: streamInfo, numberOfFiles: 7)
            
            metadata.display()
            metadata.writeToFile(filepath: self.metadataPath)
            
            self.videoIsReady = false
        }
        
        Helper.showToast(controller: self, message: "Finish recording\nfile prefix: \(recordingId)", seconds: 1)
        
    }
    
    // TODO: Move this to Helper
    private func updateGpsLocation() {
        gpsLocation = [] // Do we want to enforce valid gps location?
//        locationManager.requestWhenInUseAuthorization()
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            if let coordinate = locationManager.location?.coordinate {
                gpsLocation = [coordinate.latitude, coordinate.longitude]
            }
        }
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.backgroundColor = .systemRed
            self.recordButton.isEnabled = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        func cleanup() {
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        cleanup()
        
        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
            self.recordButton.isEnabled = true
        }
        
        videoIsReady = true
    }
}
