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
    
    private var recordingId: String!
    private var metadataPath: String!
    
    private var isRecording: Bool = false
    
    internal let sessionQueue = DispatchQueue(label: "session queue")
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
//    @IBOutlet private weak var previewView: PreviewView!
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
        
        self.loadUserDefaults()
        
        gpsLocation = [] // Do we want to enforce valid gps location?
        updateGpsLocation()
        
        self.configPopUpView()
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
        
        if isRecording {
            self.stopRecording()
        } else {
            self.updateGpsLocation()
            
            DispatchQueue.main.async {
                self.popUpView.isHidden = false
            }
            
            self.updateStartButton()
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
            
            self.recordingId = self.generateRecordingId()
            
            let recordingDataDirectoryPath = self.getRecordingDataDirectoryPath(recordingId: self.recordingId)
            
            // save metadata path, it will be used when recording is finished
            self.metadataPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((self.recordingId as NSString).appendingPathExtension("json")!)
            
            // TODO:
            // Camera data
            
            // Motion data
            self.motionManager.startRecording(dataPathString: recordingDataDirectoryPath, recordingId: self.recordingId)
            
            // Video
            self.startVideoRecording(recordingDataDirectoryPath: recordingDataDirectoryPath, recordingId: self.recordingId)
            
            self.isRecording = true
        }
    }
    
    internal func startVideoRecording(recordingDataDirectoryPath: String, recordingId: String) {
        // TODO: implement default behavior
    }
    
    private func stopRecording() {
        sessionQueue.async {
            
            var streamInfo: [StreamInfo] = self.motionManager.stopRecordingAndReturnStreamInfo()
            
            let cameraStreamInfo = self.stopVideoRecordingAndReturnStreamInfo()
            
            streamInfo.append(contentsOf: cameraStreamInfo)
            
            let username = self.firstName + " " + self.lastName
            let metadata = Metadata(username: username, userInputDescription: self.userInputDescription, sceneType: self.sceneType!, gpsLocation: self.gpsLocation, streams: streamInfo)
            
            metadata.display()
            metadata.writeToFile(filepath: self.metadataPath)
            
            self.isRecording = false
            
        }
        
        Helper.showToast(controller: self, message: "Finish recording\nfile prefix: \(recordingId)", seconds: 1)
    }
    
    internal func stopVideoRecordingAndReturnStreamInfo() -> [CameraStreamInfo] {
        // TODO: implement default behavior
        return []
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

extension CameraViewController {
    private func generateRecordingId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'hhmmssZZZ"
        let dateString = dateFormatter.string(from: Date())
        
        let recordingId = dateString + "_" + UIDevice.current.identifierForVendor!.uuidString
        
        return recordingId
    }
    
    private func getRecordingDataDirectoryPath(recordingId: String) -> String {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        // create new directory for new recording
        let documentsDirectoryUrl = URL(string: documentsDirectory)!
        let recordingDataDirectoryUrl = documentsDirectoryUrl.appendingPathComponent(recordingId)
        if !FileManager.default.fileExists(atPath: recordingDataDirectoryUrl.absoluteString) {
            do {
                try FileManager.default.createDirectory(atPath: recordingDataDirectoryUrl.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        let recordingDataDirectoryPath = recordingDataDirectoryUrl.absoluteString
        return recordingDataDirectoryPath
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
