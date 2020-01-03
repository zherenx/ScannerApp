//
//  DualCameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-23.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import UIKit

@available(iOS 13.0, *)
class DualCameraViewController: UIViewController {
    
    private let session = AVCaptureMultiCamSession()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let dataOutputQueue = DispatchQueue(label: "data output queue")
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
        case multiCamNotSupported
    }
    
    private var setupResult: SessionSetupResult = .success
    
    @IBOutlet private weak var recordButton: UIButton!
    private var isRecording = false
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private var dualCameraInput: AVCaptureDeviceInput?
    
//    private var cameraInput1: AVCaptureDeviceInput?
    private let wideAngleCameraOutput = AVCaptureMovieFileOutput()
    private weak var wideAngleCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var wideAngleCameraPreviewView: PreviewView!
    
    //    private var cameraInput2: AVCaptureDeviceInput?
    private let telephotoCameraOutput = AVCaptureMovieFileOutput()
    private weak var telephotoCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var telephotoCameraPreviewView: PreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wideAngleCameraPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        telephotoCameraPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        
        wideAngleCameraPreviewLayer = wideAngleCameraPreviewView.videoPreviewLayer
        telephotoCameraPreviewLayer = telephotoCameraPreviewView.videoPreviewLayer
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            if self.setupResult == .success {
                self.addObservers()
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func configureSession() {
//        guard setupResult == .success else { return }
//
//        guard AVCaptureMultiCamSession.isMultiCamSupported else {
//            print("MultiCam not supported on this device")
//            setupResult = .multiCamNotSupported
//            return
//        }
        
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
//            if setupResult == .success {
//                checkSystemCost()
//            }
        }
        
        // setup input
        // Use back dual camera (virtual camera, with two constituent camera)
        guard let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
            print("Could not find the dual camera")
            setupResult = .configurationFailed
            return
        }
        
        do {
            try dualCameraDevice.lockForConfiguration()
            dualCameraDevice.videoZoomFactor = 1.0
            dualCameraDevice.unlockForConfiguration()
        } catch {
            print("Error")
        }
        
        do {
            dualCameraInput = try AVCaptureDeviceInput(device: dualCameraDevice)
            
            guard let dualCameraInput = dualCameraInput, session.canAddInput(dualCameraInput) else {
                print("Could not add dual camera device input")
                setupResult = .configurationFailed
                return
            }
            
            session.addInputWithNoConnections(dualCameraInput)
        } catch {
            print("Couldn't create dual camera device input: \(error)")
            setupResult = .configurationFailed
            return
        }
        
        // setup output
        guard session.canAddOutput(wideAngleCameraOutput) else {
            print("Could not add wide-angle camera output")
            setupResult = .configurationFailed
            return
        }
        session.addOutputWithNoConnections(wideAngleCameraOutput)
        // TODO: check setting 
//        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        guard session.canAddOutput(telephotoCameraOutput) else {
            print("Could not add telephoto camera output")
            setupResult = .configurationFailed
            return
        }
        session.addOutputWithNoConnections(telephotoCameraOutput)
        
        // setup connections
        guard let widePort = dualCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: dualCameraDevice.position).first,
            let telePort = dualCameraInput!.ports(for: .video,
                                                 sourceDeviceType: .builtInTelephotoCamera,
                                                 sourceDevicePosition: dualCameraDevice.position).first
            else {
                print("Could not obtain wide and telephoto camera input ports")
                setupResult = .configurationFailed
                return
        }
        
        let wideAngleCameraConnection = AVCaptureConnection(inputPorts: [widePort], output: wideAngleCameraOutput)
        guard session.canAddConnection(wideAngleCameraConnection) else {
            print("Cannot add wide-angle input to output")
            setupResult = .configurationFailed
            return
        }
        session.addConnection(wideAngleCameraConnection)
//        wideAngleCameraConnection.videoOrientation = .portrait
        wideAngleCameraConnection.videoOrientation = .landscapeRight
        
        let telephotoCameraConnection = AVCaptureConnection(inputPorts: [telePort], output: telephotoCameraOutput)
        guard session.canAddConnection(telephotoCameraConnection) else {
            print("Cannot add telephoto input to output")
            setupResult = .configurationFailed
            return
        }
        session.addConnection(telephotoCameraConnection)
//        telephotoCameraConnection.videoOrientation = .portrait
        telephotoCameraConnection.videoOrientation = .landscapeRight
        
        // connect to preview layers
        guard let wideAngleCameraPreviewLayer = wideAngleCameraPreviewLayer else {
            setupResult = .configurationFailed
            return
        }
        let wideAngleCameraPreviewLayerConnection = AVCaptureConnection(inputPort: widePort, videoPreviewLayer: wideAngleCameraPreviewLayer)
        guard session.canAddConnection(wideAngleCameraPreviewLayerConnection) else {
            print("Could not add a connection to the wide-angle camera video preview layer")
            setupResult = .configurationFailed
            return
        }
        session.addConnection(wideAngleCameraPreviewLayerConnection)
        
        guard let telephotoCameraPreviewLayer = telephotoCameraPreviewLayer else {
            setupResult = .configurationFailed
            return
        }
        let telephotoCameraPreviewLayerConnection = AVCaptureConnection(inputPort: telePort, videoPreviewLayer: telephotoCameraPreviewLayer)
        guard session.canAddConnection(telephotoCameraPreviewLayerConnection) else {
            print("Could not add a connection to the telephoto camera video preview layer")
            setupResult = .configurationFailed
            return
        }
        session.addConnection(telephotoCameraPreviewLayerConnection)
        
    }
    
    private func addObservers() {
        // TODO: observing system pressure etc.
    }
    
    private func removeObservers() {
        // TODO:
    }
        
    @IBAction func recordButtonTapped(_ sender: Any) {
        
        self.sessionQueue.async {
            if self.isRecording {
                
//                if !self.wideAngleCameraOutput.isRecording {
//                    print("Error, wide-angle camera should be recording but it is not")
//                }
//                if !self.telephotoCameraOutput.isRecording {
//                    print("Error, telephoto camera should be recording but it is not")
//                }
                
                self.wideAngleCameraOutput.stopRecording()
                self.telephotoCameraOutput.stopRecording()
                
//                self.motionManager.stopDeviceMotionUpdates()
//                fclose(self.imuFilePointer)
            } else {
                
//                if self.wideAngleCameraOutput.isRecording {
//                    print("Error, wide-angle camera should not be recording at the moment")
//                }
//                if self.telephotoCameraOutput.isRecording {
//                    print("Error, telephoto camera should not be recording at the moment")
//                }
                
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                let wideAngleOutputConnection = self.wideAngleCameraOutput.connection(with: .video)
//                wideAngleOutputConnection?.videoOrientation = .landscapeRight
                let wideAngleAvailableVideoCodecTypes = self.wideAngleCameraOutput.availableVideoCodecTypes
                if wideAngleAvailableVideoCodecTypes.contains(.hevc) {
                    self.wideAngleCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: wideAngleOutputConnection!)
                }
                
                let telephoteOutputConnection = self.telephotoCameraOutput.connection(with: .video)
//                telephoteOutputConnection?.videoOrientation = .landscapeRight
                let telephotoAvailableVideoCodecTypes = self.telephotoCameraOutput.availableVideoCodecTypes
                if telephotoAvailableVideoCodecTypes.contains(.hevc) {
                    self.telephotoCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: telephoteOutputConnection!)
                }
                
                let fileId = NSUUID().uuidString
                let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                
                // Metadata
//                let metadataPath = (documentsDirectory as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("txt")!)
//                let metadata = Metadata(colorWidth: 16, colorHeight: 9, depthWidth: 16, depthHeight: 9, deviceId: "0001", deviceName: "device", sceneLabel: "?", sceneType: "?", username: "Hello world")
//                //                metadata.display()
//                metadata.writeToFile(filepath: metadataPath)
                
                // TODO:
                // Camera data
                
                // Motion data
//                let motionDataPath = (documentsDirectory as NSString).appendingPathComponent((fileId as NSString).appendingPathExtension("imu")!)
//                self.imuFilePointer = fopen(motionDataPath, "w")
//                self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (data, error) in
//                    if let validData = data {
//                        let motionData = MotionData(deviceMotion: validData)
//                        //                        motionData.display()
//                        motionData.writeToFile(filePointer: self.imuFilePointer!)
//                    } else {
//                        print("there is some problem with motion data")
//                    }
//                }
                
                // Video
                let wideAngleFilename = fileId + "wide"
                let wideAnglePath = (documentsDirectory as NSString).appendingPathComponent((wideAngleFilename as NSString).appendingPathExtension("mov")!)
                
                let telephotoFilename = fileId + "tele"
                let telephotoPath = (documentsDirectory as NSString).appendingPathComponent((telephotoFilename as NSString).appendingPathExtension("mov")!)
                
                self.wideAngleCameraOutput.startRecording(to: URL(fileURLWithPath: wideAnglePath), recordingDelegate: self)
                self.telephotoCameraOutput.startRecording(to: URL(fileURLWithPath: telephotoPath), recordingDelegate: self)
                
                self.isRecording = true
            }
        }
    }
}

@available(iOS 13.0, *)
extension DualCameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
            self.recordButton.setTitle("Stop", for: .normal)
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
        
        if success {
            
        } else {
            // TODO: delete file
        }
        
        cleanup()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.isEnabled = true
        }
    }
    
}
