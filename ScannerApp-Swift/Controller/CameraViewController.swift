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
import Foundation
import UIKit

class CameraViewController: UIViewController {
    
    private let defaults = UserDefaults.standard
    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    
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
    private var gpsLocation: [Double]!
    private var colorResolution: [Int]!
    private var focalLength: [Float]!
    private var principalPoint: [Float]!
    private var numColorFrames: Int!
    private var numImuMeasurements: Int!
    private var imuFrequency: Int!
    
    private var fileId: String!
    private var movieFilePath: String!
    private var metadataPath: String!
    
    private var videoIsReady: Bool = false // this is a heck, consider improve it
    
    private let session = AVCaptureSession()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let motionQueue = OperationQueue()
    
    private var defaultVideoDevice: AVCaptureDevice?

    private let movieFileOutput = AVCaptureMovieFileOutput()
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private var rotationRatePath: String!
    private var userAccelerationPath: String!
    private var magneticFieldPath: String!
    private var attitudePath: String!
    private var gravityPath: String!
    
//    private var imuFilePointer: UnsafeMutablePointer<FILE>?
    private var rotationRateFilePointer: UnsafeMutablePointer<FILE>?
    private var userAccelerationFilePointer: UnsafeMutablePointer<FILE>?
    private var magneticFieldFilePointer: UnsafeMutablePointer<FILE>?
    private var attitudeFilePointer: UnsafeMutablePointer<FILE>?
    private var gravityFilePointer: UnsafeMutablePointer<FILE>?
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var recordButton: UIButton!
    
    // pop-up view
    @IBOutlet private weak var popUpView: UIView!
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
        
        // TODO: order of these function calls might matter, consider improve on this
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
            
            self.session.sessionPreset = .photo

            if let connection = self.movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
                
                // TODO: change this and test fov value
                connection.videoOrientation = .landscapeRight
            }
        }
        
        let videoFormatDescription = defaultVideoDevice!.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription)
        
        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        colorResolution = [width, height]
        
        // TODO: calculate these
        let fov = defaultVideoDevice!.activeFormat.videoFieldOfView
        let aspect = Float(width) / Float(height)
        let t = tan(0.5 * fov)
        
        //            float fx = 0.5f * width / t;
        //            float fy = 0.5f * height / t * aspect;
        //
        //            float mx = (float)(width - 1.0f) / 2.0f;
        //            float my = (float)(height - 1.0f) / 2.0f;
        
        let fx = 0.5 * Float(width) / t
        let fy = 0.5 * Float(height) / t
        
        let mx = Float(width - 1) / 2.0
        let my = Float(height - 1) / 2.0
        
        focalLength = [fx, fy]
        principalPoint = [mx, my]
        
//        print(fov)
//        print(aspect)
//        print(width)
//        print(height)
//        print(focalLength)
//        print(principalPoint)
        
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
        
        gpsLocation = [] // Do we want to enforce valid gps location?
        updateGpsLocation()
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
        
        DispatchQueue.main.async {
            self.recordButton.isEnabled = false
        }
        
        if !self.movieFileOutput.isRecording {
            
            self.updateGpsLocation()
            
            DispatchQueue.main.async {
                self.popUpView.isHidden = false
            }
            
            self.updateStartButton()
            
        } else {
            self.stopRecording()
        }

    }
    
    @IBAction func startButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
        
        self.startRecording()
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            self.recordButton.isEnabled = true
        }
    }
    
    @IBAction func selectSceneTypeButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            if self.sceneTypePickerView.isHidden {
                self.sceneTypePickerView.isHidden = false
            } else {
                self.sceneTypePickerView.isHidden = true
            }
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
        sessionQueue.async {
            
            if UIDevice.current.isMultitaskingSupported {
                self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
            let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
            
            movieFileOutputConnection?.videoOrientation = .landscapeRight
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd'T'hhmmssZZZ"
            let dateString = dateFormatter.string(from: Date())
            
            self.fileId = dateString + "_" + UIDevice.current.identifierForVendor!.uuidString
            
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            
            // create new directory for new recording
            let docURL = URL(string: documentsDirectory)!
            let dataPath = docURL.appendingPathComponent(self.fileId)
            if !FileManager.default.fileExists(atPath: dataPath.absoluteString) {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.absoluteString, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription);
                }
            }
            
            let dataPathString = dataPath.absoluteString
            
            // save metadata path, it will be used when recording is finished
            self.metadataPath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("json")!)
            
            // TODO:
            // Camera data
            
            // Motion data
            self.numImuMeasurements = 0
            //        let motionDataPath = (dataPathString as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("imu")!)
            //        self.imuFilePointer = fopen(motionDataPath, "w")
            
            let tempHeader = "#\n"
            
            self.rotationRatePath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("rot")!)
            do {
                try tempHeader.write(to: URL(fileURLWithPath: self.rotationRatePath), atomically: true, encoding: .utf8)
            } catch {
                print("fail to write header.")
            }
            self.rotationRateFilePointer = fopen(self.rotationRatePath, "a")
            
            self.userAccelerationPath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("acce")!)
            self.userAccelerationFilePointer = fopen(self.userAccelerationPath, "w")
            
            self.magneticFieldPath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("mag")!)
            self.magneticFieldFilePointer = fopen(self.magneticFieldPath, "w")
            
            self.attitudePath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("atti")!)
            self.attitudeFilePointer = fopen(self.attitudePath, "w")
            
            self.gravityPath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("grav")!)
            self.gravityFilePointer = fopen(self.gravityPath, "w")
            
            self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
                if let validData = data {
                    self.numImuMeasurements += 1
                    let motionData = MotionData(deviceMotion: validData)
                    motionData.display()
                    //                motionData.writeToFile(filePointer: self.imuFilePointer!)
                    motionData.writeToFiles(rotationRateFilePointer: self.rotationRateFilePointer!, userAccelerationFilePointer: self.userAccelerationFilePointer!, magneticFieldFilePointer: self.magneticFieldFilePointer!, attitudeFilePointer: self.attitudeFilePointer!, gravityFilePointer: self.gravityFilePointer!)
                } else {
                    print("there is some problem with motion data")
                }
            }
            
            // Video
            self.movieFilePath = (dataPathString as NSString).appendingPathComponent((self.fileId as NSString).appendingPathExtension("mp4")!)
            self.movieFileOutput.startRecording(to: URL(fileURLWithPath: self.movieFilePath), recordingDelegate: self)
        }
    }
    
    private func stopRecording() {
        sessionQueue.async {
            
            self.movieFileOutput.stopRecording()
            
            self.motionManager.stopDeviceMotionUpdates()
//            fclose(self.imuFilePointer)
            fclose(self.rotationRateFilePointer)
            fclose(self.userAccelerationFilePointer)
            fclose(self.magneticFieldFilePointer)
            fclose(self.attitudeFilePointer)
            fclose(self.gravityFilePointer)
            
            self.numColorFrames = self.getNumberOfFrames(videoUrl: URL(fileURLWithPath: self.movieFilePath))
            
            let endian = "little"
            let rotHeader = "#rot \(self.numImuMeasurements!) 3 \(endian)\n";
            do {
                let fileHandle = try FileHandle(forUpdating: URL(fileURLWithPath: self.rotationRatePath))
                fileHandle.seek(toFileOffset: 0)
                fileHandle.write(rotHeader.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {
                print("fail to re-write header.")
            }
            
            let username = self.firstName! + " " + self.lastName!
            let metadata = Metadata(username: username, userInputDescription: self.userInputDescription!, sceneType: self.sceneType!, gpsLocation: self.gpsLocation, streams: self.generateStreamInfo())
            
//            metadata.display()
            metadata.writeToFile(filepath: self.metadataPath)
            
        }
        
        Helper.showToast(controller: self, message: "Finish recording\nfile prefix: \(fileId)", seconds: 1)
        
        videoIsReady = false
    }
    
    private func generateStreamInfo() -> [StreamInfo] {
        let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: "color_camera", encoding: "h264", num_frames: numColorFrames, resolution: colorResolution, focal_length: focalLength, principal_point: principalPoint, extrinsics_matrix: nil)
        
        let rotationRateStreamInfo = ImuStreamInfo(id: "rot_1", type: "rotation_rate", encoding: "bin", num_frames: numImuMeasurements, frequency: imuFrequency)
        let userAccelerationStreamInfo = ImuStreamInfo(id: "acce_1", type: "user_acceleration", encoding: "bin", num_frames: numImuMeasurements, frequency: imuFrequency)
        let magneticFieldStreamInfo = ImuStreamInfo(id: "mag_1", type: "magnetic_field", encoding: "bin", num_frames: numImuMeasurements, frequency: imuFrequency)
        let attitudeStreamInfo = ImuStreamInfo(id: "atti_1", type: "attitude", encoding: "bin", num_frames: numImuMeasurements, frequency: imuFrequency)
        let gravityStreamInfo = ImuStreamInfo(id: "grav_1", type: "gravity", encoding: "bin", num_frames: numImuMeasurements, frequency: imuFrequency)

        return [cameraStreamInfo, rotationRateStreamInfo, userAccelerationStreamInfo, magneticFieldStreamInfo, attitudeStreamInfo, gravityStreamInfo]
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
    
    // https://stackoverflow.com/questions/29506411/ios-determine-number-of-frames-in-video
    private func getNumberOfFrames(videoUrl url: URL) -> Int {
        
        while !videoIsReady {
            // this is a heck
            // wait until video is ready
//            print("waiting for video ...")
            usleep(10000)
        }
        
        let asset = AVURLAsset(url: url, options: nil)
        do {
            let reader = try AVAssetReader(asset: asset)
            //AVAssetReader(asset: asset, error: nil)
            
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
            
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
            reader.add(readerOutput)
            reader.startReading()
            
            var nFrames = 0
            
            while true {
                let sampleBuffer = readerOutput.copyNextSampleBuffer()
                if sampleBuffer == nil {
                    break
                }
                
                nFrames += 1
            }
            
            return nFrames
            
        } catch {
            print("Error: \(error)")
        }
        
        return 0
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
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

extension CameraViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldDidUpdate(textField)
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textFieldDidUpdate(textField)
        
        return true
    }
    
    private func textFieldDidUpdate(_ textField: UITextField) {
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
