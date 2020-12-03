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
    
    
    
    @IBOutlet private weak var recordButton: UIButton!
    private var isRecording = false
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private var extrinsics: Data?
    
//    private var dualCameraInput: AVCaptureDeviceInput?
    
    private var wideAngleInput: AVCaptureDeviceInput?
    private var telephotoInput: AVCaptureDeviceInput?
    
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
            if !self.session.isRunning {
                self.addObservers()
                self.session.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    private func configureSession() {
        
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        // setup input
        // Use back dual camera (virtual camera, with two constituent camera)
//        guard let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
//            print("Could not find the dual camera")
//            return
//        }
        
        guard let wideAngleDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the wide angle camera")
            return
        }
        
        guard let telephotoDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else {
            print("Could not find the telephoto camera")
            return
        }
        
        
        
        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: nil, position: .back), let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: nil, position: .back) {
            self.extrinsics = AVCaptureDevice.extrinsicMatrix(from: tele, to: wide)
            
            let matrix: matrix_float4x3 = self.extrinsics!.withUnsafeBytes { $0.pointee }
            
            print(matrix)
            
            
        }
        
//        do {
//            dualCameraInput = try AVCaptureDeviceInput(device: dualCameraDevice)
//
//            guard let dualCameraInput = dualCameraInput, session.canAddInput(dualCameraInput) else {
//                print("Could not add dual camera device input")
//                return
//            }
//
//            session.addInputWithNoConnections(dualCameraInput)
//        } catch {
//            print("Couldn't create dual camera device input: \(error)")
//            return
//        }
        
        do {
            wideAngleInput = try AVCaptureDeviceInput(device: wideAngleDevice)
            
            guard let wideAngleInput = wideAngleInput, session.canAddInput(wideAngleInput) else {
                print("Could not add wide angle camera device input")
                return
            }
            
            session.addInputWithNoConnections(wideAngleInput)
        } catch {
            print("Couldn't create wide angle camera device input: \(error)")
            return
        }
        
        do {
            telephotoInput = try AVCaptureDeviceInput(device: telephotoDevice)
            
            guard let telephotoInput = telephotoInput, session.canAddInput(telephotoInput) else {
                print("Could not add telephoto camera device input")
                return
            }
            
            session.addInputWithNoConnections(telephotoInput)
        } catch {
            print("Couldn't create telephoto camera device input: \(error)")
            return
        }
        
        
        
        
        // setup output
        guard session.canAddOutput(wideAngleCameraOutput) else {
            print("Could not add wide-angle camera output")
            return
        }
        session.addOutputWithNoConnections(wideAngleCameraOutput)
        // TODO: check setting 
//        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        guard session.canAddOutput(telephotoCameraOutput) else {
            print("Could not add telephoto camera output")
            return
        }
        session.addOutputWithNoConnections(telephotoCameraOutput)
        
        // setup connections
        guard let port1 = wideAngleInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: wideAngleDevice.position).first
        else {
                print("Could not obtain wide angle camera input ports")
                return
        }
//        guard let port2 = telephotoInput!.ports(for: .video,
//                                                   sourceDeviceType: .builtInTelephotoCamera,
//                                                   sourceDevicePosition: telephotoDevice.position).first
//        else {
//            print("Could not obtain telephoto camera input ports")
//            return
//        }
        guard let port2 = telephotoInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInUltraWideCamera,
                                                   sourceDevicePosition: telephotoDevice.position).first
        else {
            print("Could not obtain ultrawide camera input ports")
            return
        }
        
        let wideAngleCameraConnection = AVCaptureConnection(inputPorts: [port1], output: wideAngleCameraOutput)
        guard session.canAddConnection(wideAngleCameraConnection) else {
            print("Cannot add wide-angle input to output")
            return
        }
        session.addConnection(wideAngleCameraConnection)
//        wideAngleCameraConnection.videoOrientation = .portrait
        wideAngleCameraConnection.videoOrientation = .landscapeRight
        
        let telephotoCameraConnection = AVCaptureConnection(inputPorts: [port2], output: telephotoCameraOutput)
        guard session.canAddConnection(telephotoCameraConnection) else {
            print("Cannot add telephoto input to output")
            return
        }
        session.addConnection(telephotoCameraConnection)
//        telephotoCameraConnection.videoOrientation = .portrait
        telephotoCameraConnection.videoOrientation = .landscapeRight
        
        // connect to preview layers
        guard let wideAngleCameraPreviewLayer = wideAngleCameraPreviewLayer else {
            return
        }
        let wideAngleCameraPreviewLayerConnection = AVCaptureConnection(inputPort: port1, videoPreviewLayer: wideAngleCameraPreviewLayer)
        guard session.canAddConnection(wideAngleCameraPreviewLayerConnection) else {
            print("Could not add a connection to the wide-angle camera video preview layer")
            return
        }
        session.addConnection(wideAngleCameraPreviewLayerConnection)
        
        guard let telephotoCameraPreviewLayer = telephotoCameraPreviewLayer else {
            return
        }
        let telephotoCameraPreviewLayerConnection = AVCaptureConnection(inputPort: port2, videoPreviewLayer: telephotoCameraPreviewLayer)
        guard session.canAddConnection(telephotoCameraPreviewLayerConnection) else {
            print("Could not add a connection to the telephoto camera video preview layer")
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
                self.stopRecording()
            } else {
                self.startRecoring()
            }
        }
    }
    
    private func startRecoring() {
        
//        if self.wideAngleCameraOutput.isRecording {
//            print("Error, wide-angle camera should not be recording at the moment")
//        }
//        if self.telephotoCameraOutput.isRecording {
//            print("Error, telephoto camera should not be recording at the moment")
//        }
        
        if UIDevice.current.isMultitaskingSupported {
            self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
        
        let wideAngleOutputConnection = self.wideAngleCameraOutput.connection(with: .video)
        wideAngleOutputConnection?.videoOrientation = .landscapeRight
        //                let wideAngleAvailableVideoCodecTypes = self.wideAngleCameraOutput.availableVideoCodecTypes
        //                if wideAngleAvailableVideoCodecTypes.contains(.hevc) {
        //                    self.wideAngleCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: wideAngleOutputConnection!)
        //                }
        
        let telephoteOutputConnection = self.telephotoCameraOutput.connection(with: .video)
        telephoteOutputConnection?.videoOrientation = .landscapeRight
        //                let telephotoAvailableVideoCodecTypes = self.telephotoCameraOutput.availableVideoCodecTypes
        //                if telephotoAvailableVideoCodecTypes.contains(.hevc) {
        //                    self.telephotoCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: telephoteOutputConnection!)
        //                }
        
        let recordingId = Helper.getRecordingId()
        let recordingDataDirectoryPath = Helper.getRecordingDataDirectoryPath(recordingId: recordingId)
        
        // Video
        let wideAngleFilename = recordingId + "-wide"
        let wideAnglePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((wideAngleFilename as NSString).appendingPathExtension("mp4")!)
        
        let telephotoFilename = recordingId + "-tele"
        let telephotoPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((telephotoFilename as NSString).appendingPathExtension("mp4")!)
        
        self.wideAngleCameraOutput.startRecording(to: URL(fileURLWithPath: wideAnglePath), recordingDelegate: self)
        self.telephotoCameraOutput.startRecording(to: URL(fileURLWithPath: telephotoPath), recordingDelegate: self)
        
        self.isRecording = true
    }
    
    private func stopRecording() {
        
//        if !self.wideAngleCameraOutput.isRecording {
//            print("Error, wide-angle camera should be recording but it is not")
//        }
//        if !self.telephotoCameraOutput.isRecording {
//            print("Error, telephoto camera should be recording but it is not")
//        }
        
        self.wideAngleCameraOutput.stopRecording()
        self.telephotoCameraOutput.stopRecording()
    }
}

@available(iOS 13.0, *)
extension DualCameraViewController: AVCaptureFileOutputRecordingDelegate {
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
        
        if success {
            
        } else {
            // TODO: delete file
        }
        
        cleanup()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
            self.recordButton.isEnabled = true
        }
    }
    
}
