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
    private let userInputDescriptionKey = "userInputDescription"
    private let sceneTypeKey = "sceneTypeKey"
    
    private var firstName: String?
    private var lastName: String?
    private var userInputDescription: String?
    private var sceneType: String?
    
    private var gpsLocation: String!
    
    
    private var colorResolution: [Int]!
    private var focalLength: [Float]!
    private var principalPoint: [Float]!
    
    private var numColorFrames: Int!
    private var numImuMeasurements: Int!
    private var imuFrequency: Int!
    
    
    
    
//    private var fileId: String?
    private var metadataPath: String! // this is a hack
    
    
    private let sessionQueue = DispatchQueue(label: "session queue")
//    private let motionQueue = DispatchQueue(label: "motion queue")
    private let motionQueue = OperationQueue()
    
    private let session = AVCaptureSession()
    
    private var defaultVideoDevice: AVCaptureDevice?
    
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
        
        self.loadUserDefaults()
        
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
//            var defaultVideoDevice: AVCaptureDevice?

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
            
            
            // TODO:
//            colorResolution = [1920, 1080]
            focalLength = [1.0, 2.0]
            principalPoint = [3.0, 4.0]

            
            
            
            
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
            self.session.sessionPreset = .photo
//            self.session.sessionPreset = .hd1920x1080
            
            
            
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
        
        
        let videoFormatDescription = defaultVideoDevice!.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription)
        colorResolution = [Int(dimensions.width), Int(dimensions.height)]
        
        self.session.commitConfiguration()
        
    }
    
    private func setupIMU() {
        self.numImuMeasurements = 0
        self.imuFrequency = 60
        self.motionManager.deviceMotionUpdateInterval = 1.0 / Double(self.imuFrequency)
        self.motionQueue.maxConcurrentOperationCount = 1
    }
    
    private func loadUserDefaults() {
        
        firstName = defaults.string(forKey: firstNameKey)
        lastName = defaults.string(forKey: lastNameKey)
        
        userInputDescription = defaults.string(forKey: userInputDescriptionKey)
        sceneType = "scene type ???"
//        sceneType = defaults.string(forKey: sceneTypeKey)
        
//        userInputDescription = defaults.string(forKey: userInputKey)
//        sceneType = defaults.string(forKey: sceneTypeKey)
        
        gpsLocation = "gps location ???"
        
        
        
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
                
                let alert = UIAlertController(title: "Alert Title", message: "Alert Message", preferredStyle: .alert)
                
                let saveAction = UIAlertAction(title: "Save", style: .default) { (action: UIAlertAction!) -> Void in
                    
                    self.defaults.set(self.firstName, forKey: self.firstNameKey)
                    self.defaults.set(self.lastName, forKey: self.lastNameKey)
                    self.defaults.set(self.userInputDescription, forKey: self.userInputDescriptionKey)

                    self.sessionQueue.async {
                        self.startRecording()
                    }
                }

                saveAction.isEnabled = false
                if self.firstName != nil && !self.firstName!.isEmpty
                && self.lastName != nil && !self.lastName!.isEmpty
                && self.userInputDescription != nil && !self.userInputDescription!.isEmpty
                && self.sceneType != nil {
                    saveAction.isEnabled = true
                }

                let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action: UIAlertAction!) -> Void in
                    self.recordButton.isEnabled = true
                }
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Please enter first name"
                    textField.text = self.firstName
                }

                alert.addTextField { (textField) in
                    textField.placeholder = "Please enter last name"
                    textField.text = self.lastName
                }
                
                alert.addTextField { (textField) in
                    textField.placeholder = "Please enter scene description"
                    textField.text = self.userInputDescription
                }

                NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object:alert.textFields?[0], queue: OperationQueue.main) { (notification) -> Void in

                    self.firstName = alert.textFields![0].text
                    self.lastName = alert.textFields![1].text
                    self.userInputDescription = alert.textFields![2].text

                    if self.firstName != nil && !self.firstName!.isEmpty
                        && self.lastName != nil && !self.lastName!.isEmpty
                        && self.userInputDescription != nil && !self.userInputDescription!.isEmpty
                        && self.sceneType != nil {
                        saveAction.isEnabled = true
                    } else {
                        saveAction.isEnabled = false
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object:alert.textFields?[1], queue: OperationQueue.main) { (notification) -> Void in

                    self.firstName = alert.textFields![0].text
                    self.lastName = alert.textFields![1].text
                    self.userInputDescription = alert.textFields![2].text

                    if self.firstName != nil && !self.firstName!.isEmpty
                        && self.lastName != nil && !self.lastName!.isEmpty
                        && self.userInputDescription != nil && !self.userInputDescription!.isEmpty
                        && self.sceneType != nil {
                        saveAction.isEnabled = true
                    } else {
                        saveAction.isEnabled = false
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object:alert.textFields?[2], queue: OperationQueue.main) { (notification) -> Void in

                    self.firstName = alert.textFields![0].text
                    self.lastName = alert.textFields![1].text
                    self.userInputDescription = alert.textFields![2].text

                    if self.firstName != nil && !self.firstName!.isEmpty
                        && self.lastName != nil && !self.lastName!.isEmpty
                        && self.userInputDescription != nil && !self.userInputDescription!.isEmpty
                        && self.sceneType != nil {
                        saveAction.isEnabled = true
                    } else {
                        saveAction.isEnabled = false
                    }
                }
                
                // TODO: add a pickerview here
                
                alert.addAction(cancelAction)
                alert.addAction(saveAction)

                self.present(alert, animated: true, completion: nil)
                
//                self.startRecording()
            } else {
                self.stopRecording()
            }
        }
    }
    
    private func startRecording() {
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
        
        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'hhmmssZZZ"
        let dateString = dateFormatter.string(from: Date())
        
        let fileId = dateString + "_" + UIDevice.current.identifierForVendor!.uuidString
//        let fileId = NSUUID().uuidString
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        // create new directory for new recording
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent(fileId)
        if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        let dataPathString = dataPath.absoluteString
        
        // save metadata path, it will be used when recording is finished
        self.metadataPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("json")!)
        
        // TODO:
        // Camera data
        
        // Motion data
        self.numImuMeasurements = 0
        let motionDataPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("imu")!)
        self.imuFilePointer = fopen(motionDataPath, "w")
        self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
            if let validData = data {
                self.numImuMeasurements += 1
                let motionData = MotionData(deviceMotion: validData)
                //                        motionData.display()
                motionData.writeToFile(filePointer: self.imuFilePointer!)
            } else {
                print("there is some problem with motion data")
            }
        }
        
        // Video
        let movieFilePath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("mp4")!)
        self.movieFileOutput.startRecording(to: URL(fileURLWithPath: movieFilePath), recordingDelegate: self)
    }
    
    private func stopRecording() {
        self.movieFileOutput.stopRecording()
        
        // TODO: get numColorFrames
        self.numColorFrames = 9999
        
        
        
        self.motionManager.stopDeviceMotionUpdates()
        fclose(self.imuFilePointer)
        
        let username = self.firstName! + " " + self.lastName!
        //                let metadata = Metadata(deviceId: self.deviceId, modelName: self.modelName, sceneLabel: self.sceneLabel, sceneType: self.sceneType, sensorTypes: self.sensorTypes, numMeasurements: ["numColorFrames": 9999, "numImuMeasurements": 9998], username: username, userInputDescription: self.userInputDescription, colorWidth: 16, colorHeight: 9)
        
        
        
        let metadata = Metadata(username: username, userInputDescription: self.userInputDescription!, sceneType: self.sceneType!, gpsLocation: self.gpsLocation, streams: self.generateStreamInfo())
        
        
        metadata.display()
        metadata.writeToFile(filepath: self.metadataPath)
    }
    
    private func generateStreamInfo() -> [StreamInfo] {
        let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: "color_camera", encoding: "h264", num_frames: numColorFrames, resolution: colorResolution, focal_length: focalLength, principal_point: principalPoint, extrinsics_matrix: nil)
        let accelerometerStreamInfo = ImuStreamInfo(id: "accel_1", type: "accelerometer", encoding: "accel_bin", num_frames: numImuMeasurements, frequency: imuFrequency)
        // TOOD: more imu streams
        return [cameraStreamInfo, accelerometerStreamInfo]
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
