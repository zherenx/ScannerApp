//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import CoreMotion
import UIKit

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    private let defaults = UserDefaults.standard
    
    private let firstNameKey = "firstName"
    private let lastNameKey = "lastName"
    
    
    
    private var deviceId: String!
    private var modelName: String!
    private var sceneLabel: String!
    private var sceneType: String!
    
    private var sensorTypes: [String] = ["sensor 1", "sensor 2"]
//    private var numMeasurements: [String: Int]!
    
    private var firstName: String!
    private var lastName: String!
    private var userInputDescription: String!
    
    
    
    private let sessionQueue = DispatchQueue(label: "session queue")
//    private let motionQueue = DispatchQueue(label: "motion queue")
    private let motionQueue = OperationQueue()
    
    private let session = AVCaptureSession()
//    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let motionManager = CMMotionManager()
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    private var imuFilePointer: UnsafeMutablePointer<FILE>?
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previewView.videoPreviewLayer.session = self.session
        
        // TODO: authorization check
        
        self.configurateSession()
        self.setupIMU()
        
        
        
        
        self.loadUserDefaultsAndDeviceInfo()
        
        
//        print(defaults.string(forKey: firstNameKey) ?? "No value for first name")
//        print(defaults.string(forKey: lastNameKey) ?? "No value for last name")
        
        
        
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func configurateSession() {
        self.session.beginConfiguration()
        
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
//                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            
            
            
            
            do {
                try videoDevice.lockForConfiguration()
                
                let targetFrameDuration = CMTimeMake(value: 1, timescale: 30)
                videoDevice.activeVideoMaxFrameDuration = targetFrameDuration
                videoDevice.activeVideoMinFrameDuration = targetFrameDuration
                
                videoDevice.unlockForConfiguration()
            } catch {
                print("Error configurating video device")
            }
            
            
            
            
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
//                self.videoDeviceInput = videoDeviceInput

//                DispatchQueue.main.async {
//                    /*
//                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
//                     You can manipulate UIView only on the main thread.
//                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
//                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
//
//                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
//                     handled by CameraViewController.viewWillTransition(to:with:).
//                     */
//                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
//                    if self.windowOrientation != .unknown {
//                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
//                            initialVideoOrientation = videoOrientation
//                        }
//                    }
//
//                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
//                    self.previewView.videoPreviewLayer.connection?.videoOrientation = .portrait
//                }
            } else {
                print("Couldn't add video device input to the session.")
//                setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
//            setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
        
        
        
        // config output
//        let outputSettings = NSDictionary(object: NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), forKey: NSString(string: kCVPixelBufferPixelFormatTypeKey))
//        self.movieFileOutput.setOutputSettings(outputSettings, for: <#T##AVCaptureConnection#>)
        
        
        if self.session.canAddOutput(self.movieFileOutput) {
//            self.session.beginConfiguration()
            self.session.addOutput(self.movieFileOutput)
            
            
            
//            self.session.sessionPreset = .high
//            self.session.sessionPreset = .photo
            self.session.sessionPreset = .hd1920x1080
            
            
            
            if let connection = self.movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
//            self.session.commitConfiguration()
            
//            DispatchQueue.main.async {
//                captureModeControl.isEnabled = true
//            }
//
//            self.movieFileOutput = movieFileOutput
//
//            DispatchQueue.main.async {
//                self.recordButton.isEnabled = true
//
//                /*
//                 For photo captures during movie recording, Speed quality photo processing is prioritized
//                 to avoid frame drops during recording.
//                 */
//                self.photoQualityPrioritizationSegControl.selectedSegmentIndex = 0
//                self.photoQualityPrioritizationSegControl.sendActions(for: UIControl.Event.valueChanged)
//            }
        }
        
        self.session.commitConfiguration()
        
    }
    
    private func setupIMU() {
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        self.motionQueue.maxConcurrentOperationCount = 1
    }
    
    private func loadUserDefaultsAndDeviceInfo() {
        
        deviceId = UIDevice.current.identifierForVendor?.uuidString
        modelName = "model name ???"
        sceneLabel = "scene label ???"
        sceneType = "scene type ???"
        
        firstName = defaults.string(forKey: firstNameKey)
        lastName = defaults.string(forKey: lastNameKey)
        userInputDescription = "user input ???"
        
        
        
//        print(UIDevice.current.name)
//        print(UIDevice.current.systemName)
//        print(UIDevice.current.systemVersion)
//        print(UIDevice.current.model)
//        print(UIDevice.current.localizedModel)
//        print(UIDevice.current.identifierForVendor)
        
        
    
    }
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
    
//        guard let movieFileOutput = self.movieFileOutput else {
//            return
//        }
        
        self.recordButton.isEnabled = false
        
//        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        self.sessionQueue.async {
            if !self.movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
//                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                movieFileOutputConnection?.videoOrientation = .landscapeRight
                
//                let availableVideoCodecTypes = self.movieFileOutput.availableVideoCodecTypes
//
//                print(availableVideoCodecTypes)
//
//
//                if availableVideoCodecTypes.contains(.hevc) {
//                    self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
//                }
                
                
                
                
                let uuid = NSUUID().uuidString
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                // create new directory for new recording


                let docURL = URL(string: documentsDirectory)!
                let dataPath = docURL.appendingPathComponent(uuid)
                if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
                    do {
                        try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
                    } catch {
                        print(error.localizedDescription);
                    }
                }
                
                let dataPathString = dataPath.absoluteString
                
                // Metadata
                let username = self.firstName + " " + self.lastName
                let metadataPath = (dataPathString as NSString).appendingPathComponent((uuid as NSString).appendingPathExtension("txt")!)
//                let metadata = Metadata(colorWidth: 0, colorHeight: 0, depthWidth: 0, depthHeight: 0, deviceId: "0001", modelName: self.deviceName, sceneLabel: "?", sceneType: "?", username: username)
                let metadata = Metadata(deviceId: self.deviceId, modelName: self.modelName, sceneLabel: self.sceneLabel, sceneType: self.sceneType, sensorTypes: self.sensorTypes, numMeasurements: ["numColorFrames": 9999, "numImuMeasurements": 9998], username: username, userInputDescription: self.userInputDescription, colorWidth: 16, colorHeight: 9)
                
                metadata.display()
                metadata.writeToFile(filepath: metadataPath)
                
                // TODO:
                // Camera data
                
                // Motion data
                let motionDataPath = (dataPathString as NSString).appendingPathComponent((uuid as NSString).appendingPathExtension("imu")!)
                self.imuFilePointer = fopen(motionDataPath, "w")
                self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
                    if let validData = data {
                        let motionData = MotionData(deviceMotion: validData)
//                        motionData.display()
                        motionData.writeToFile(filePointer: self.imuFilePointer!)
                    } else {
                        print("there is some problem with motion data")
                    }
                }
                
                // Video
                let movieFilePath = (dataPathString as NSString).appendingPathComponent((uuid as NSString).appendingPathExtension("mp4")!)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: movieFilePath), recordingDelegate: self)
            } else {
                self.movieFileOutput.stopRecording()
                
                self.motionManager.stopDeviceMotionUpdates()
                fclose(self.imuFilePointer)
            }
        }
        
    }
    
    /// - Tag: DidStartRecording
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.backgroundColor = .systemRed
            self.recordButton.isEnabled = true
        }
    }
    
    /// - Tag: DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
//            let path = outputFileURL.path
//            if FileManager.default.fileExists(atPath: path) {
//                do {
//                    try FileManager.default.removeItem(atPath: path)
//                } catch {
//                    print("Could not remove file at url: \(outputFileURL)")
//                }
//            }
            
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
        
//        if success {
//            // Check the authorization status.
//            PHPhotoLibrary.requestAuthorization { status in
//                if status == .authorized {
//                    // Save the movie file to the photo library and cleanup.
//                    PHPhotoLibrary.shared().performChanges({
//                        let options = PHAssetResourceCreationOptions()
//                        options.shouldMoveFile = true
//                        let creationRequest = PHAssetCreationRequest.forAsset()
//                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
//                    }, completionHandler: { success, error in
//                        if !success {
//                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
//                        }
//                        cleanup()
//                    }
//                    )
//                } else {
//                    cleanup()
//                }
//            }
//        } else {
//            cleanup()
//        }
        
        if success {
            
        } else {
            // TODO: delete file
        }
        
        cleanup()
        
        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            // Only enable the ability to change camera if the device has more than one camera.
//            self.cameraButton.isEnabled = self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
            
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
            self.recordButton.isEnabled = true
            
//            self.captureModeControl.isEnabled = true
//            self.recordButton.setImage(#imageLiteral(resourceName: "CaptureVideo"), for: [])
        }
    }
}
