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

class CameraViewController: UIViewController {
    
    private let defaults = UserDefaults.standard
    private let locationManager = CLLocationManager()
    
    private let firstNameKey = Constants.UserDefaultsKeys.firstNameKey
    private let lastNameKey = Constants.UserDefaultsKeys.lastNameKey
    private let userInputDescriptionKey = Constants.UserDefaultsKeys.userInputDescriptionKey
    private let sceneTypeIndexKey = Constants.UserDefaultsKeys.sceneTypeIndexKey
    private let sceneTypeKey = Constants.UserDefaultsKeys.sceneTypeKey
    
    private let sceneTypes = Constants.sceneTypes
    
    private var firstName: String?
    private var lastName: String?
    private var userInputDescription: String?
    private var sceneType: String?
    
//    private var gpsLocation: String!
    private var gpsLocation: [Double]!
    
    
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
    
    @IBOutlet private weak var popUpView: UIView!
//    private var popUpView: UIView!
    
    @IBOutlet private weak var firstNameTextField: UITextField!
    @IBOutlet private weak var lastNameTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var selectSceneTypeButton: UIButton!
    @IBOutlet private weak var sceneTypePickerView: UIPickerView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        self.previewView.videoPreviewLayer.session = self.session
        
        self.configurateSession()
        self.setupIMU()
        
        self.loadUserDefaults()
        self.configPopUpView()
        
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
        
        updateSceneType()
//        let currentSceneTypeIndex = defaults.integer(forKey: sceneTypeIndexKey)
//        if currentSceneTypeIndex == 0 {
//            sceneType = nil
//        } else {
//            sceneType = sceneTypes[currentSceneTypeIndex]
//        }
//        sceneType = defaults.string(forKey: sceneTypeKey)
        
//        userInputDescription = defaults.string(forKey: userInputKey)
        
//        gpsLocation = "gps location ???"
        
        gpsLocation = [] // Do we want to enforce valid gps location?
        updateGpsLocation()
        
        
        
        
        
//        print(UIDevice.current.name)
//        print(UIDevice.current.systemName)
//        print(UIDevice.current.systemVersion)
//        print(UIDevice.current.model)
//        print(UIDevice.current.localizedModel)
//        print(UIDevice.current.identifierForVendor)
        
        
    
    }
    
    private func updateSceneType() {
        let currentSceneTypeIndex = defaults.integer(forKey: sceneTypeIndexKey)
        if currentSceneTypeIndex == 0 {
            sceneType = nil
        } else {
            sceneType = sceneTypes[currentSceneTypeIndex]
        }
    }
    
    private func configPopUpView() {
        popUpView.isHidden = true
//        startButton.isEnabled = false
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        descriptionTextField.delegate = self
        
        firstNameTextField.tag = Constants.Tag.firstNameTag
        lastNameTextField.tag = Constants.Tag.lastNameTag
        descriptionTextField.tag = Constants.Tag.descriptionTag
        
        firstName = defaults.string(forKey: firstNameKey)
        lastName = defaults.string(forKey: lastNameKey)
        userInputDescription = defaults.string(forKey: userInputDescriptionKey)
        
        firstNameTextField.text = firstName
        lastNameTextField.text = lastName
        descriptionTextField.text = userInputDescription
        
        // setup picker view
        sceneTypePickerView.delegate = self
        sceneTypePickerView.dataSource = self

        sceneTypePickerView.isHidden = true
        
        let currentSceneTypeIndex = defaults.integer(forKey: sceneTypeIndexKey)
        selectSceneTypeButton.setTitle(sceneTypes[currentSceneTypeIndex], for: .normal)
        
        sceneTypePickerView.selectRow(currentSceneTypeIndex, inComponent: 0, animated: false)
    }
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
    
//        guard let movieFileOutput = self.movieFileOutput else {
//            return
//        }
        
        self.recordButton.isEnabled = false
        
//        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        self.sessionQueue.async {
            if !self.movieFileOutput.isRecording {
                
                self.updateGpsLocation()
                
                DispatchQueue.main.async {
                    self.popUpView.isHidden = false
                    self.updateStartButton()
                }
                
                
                

                
//                self.startRecording()
            } else {
                self.stopRecording()
            }
        }
    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        self.popUpView.isHidden = true
        self.sessionQueue.async {
            self.startRecording()
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.popUpView.isHidden = true
        self.recordButton.isEnabled = true
    }
    
    @IBAction func selectSceneTypeButtonTapped(_ sender: Any) {
        if sceneTypePickerView.isHidden {
            sceneTypePickerView.isHidden = false
        } else {
            sceneTypePickerView.isHidden = true
        }
    }
    
    private func hasAllRequiredProperties() -> Bool {
        if self.firstName != nil && !self.firstName!.isEmpty
            && self.lastName != nil && !self.lastName!.isEmpty
            && self.userInputDescription != nil && !self.userInputDescription!.isEmpty
            && self.sceneType != nil {
            return true
        } else {
            return false
        }
    }
    
    private func updateStartButton() {
        DispatchQueue.main.async {
            if self.hasAllRequiredProperties() {
                self.startButton.isEnabled = true
            } else {
                self.startButton.isEnabled = false
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

extension CameraViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        var text = textField.text?.trimmingCharacters(in: .whitespaces)

        if text != nil && text!.isEmpty {
            text = nil
        }
        
        switch textField.tag {
        case Constants.Tag.firstNameTag:
            firstName = text
            defaults.set(text, forKey: firstNameKey)
        case Constants.Tag.lastNameTag:
            lastName = text
            defaults.set(text, forKey: lastNameKey)
        case Constants.Tag.descriptionTag:
            userInputDescription = text
            defaults.set(text, forKey: userInputDescriptionKey)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
        
        updateStartButton()
        
        return true
    }
}

extension CameraViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sceneTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sceneTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        defaults.set(row, forKey: sceneTypeIndexKey)
        selectSceneTypeButton.setTitle(sceneTypes[row], for: .normal)
        
        updateSceneType()
        updateStartButton()
    }
}
