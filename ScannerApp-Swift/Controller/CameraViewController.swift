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
    
    private let locationManager = CLLocationManager()
    private let motionManager = MotionManager.instance
    
    private let sceneTypes = Constants.sceneTypes

    private var firstName: String = ""
    private var lastName: String = ""
    private var userInputDescription: String = ""
    private var sceneType: String?
    private var gpsLocation: [Double]!
    private var colorResolution: [Int]!
    private var focalLength: [Float]!
    private var principalPoint: [Float]!
    
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
        
        self.loadUserDefaults()
        
        gpsLocation = [] // Do we want to enforce valid gps location?
        updateGpsLocation()
        
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
    
    private func loadUserDefaults() {
        
        firstName = UserDefaults.firstName
        lastName = UserDefaults.lastName
        
        userInputDescription = UserDefaults.userInputDescription
        
        updateSceneType()
    }
    
    private func updateSceneType() {
        let currentSceneTypeIndex = UserDefaults.sceneTypeIndex
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
        
        firstName = UserDefaults.firstName
        lastName = UserDefaults.lastName
        userInputDescription = UserDefaults.userInputDescription
        
        firstNameTextField.text = firstName
        lastNameTextField.text = lastName
        descriptionTextField.text = userInputDescription
        
        // setup picker view
        sceneTypePickerView.delegate = self
        sceneTypePickerView.dataSource = self

        sceneTypePickerView.isHidden = true
        
        let currentSceneTypeIndex = UserDefaults.sceneTypeIndex
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
        if !self.firstName.isEmpty
            && !self.lastName.isEmpty
            && !self.userInputDescription.isEmpty
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
            
            let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, num_frames: numColorFrames, resolution: self.colorResolution, focal_length: self.focalLength, principal_point: self.principalPoint, extrinsics_matrix: nil)
            
            streamInfo.append(cameraStreamInfo)
            
            let username = self.firstName + " " + self.lastName
            let metadata = Metadata(username: username, userInputDescription: self.userInputDescription, sceneType: self.sceneType!, gpsLocation: self.gpsLocation, streams: streamInfo)
            
            metadata.display()
            metadata.writeToFile(filepath: self.metadataPath)
            
        }
        
        Helper.showToast(controller: self, message: "Finish recording\nfile prefix: \(recordingId)", seconds: 1)
        
        videoIsReady = false
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
        
        let text: String = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        
        switch textField.tag {
        case Constants.Tag.firstNameTag:
            firstName = text
            UserDefaults.set(firstName: text)
        case Constants.Tag.lastNameTag:
            lastName = text
            UserDefaults.set(lastName: text)
        case Constants.Tag.descriptionTag:
            userInputDescription = text
            UserDefaults.set(userInputDescription: text)
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
        UserDefaults.set(sceneTypeIndex: row)
        selectSceneTypeButton.setTitle(sceneTypes[row], for: .normal)
        
        updateSceneType()
        updateStartButton()
    }
}
