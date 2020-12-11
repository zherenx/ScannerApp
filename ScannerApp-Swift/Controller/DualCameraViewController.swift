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
    
    private var extrinsics: Data?
    
    private var mainCameraInput: AVCaptureDeviceInput?
    private let mainCameraOutput = AVCaptureMovieFileOutput()
    private weak var mainCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var mainCameraPreviewView: PreviewView!
    
    private var secondaryCameraInput: AVCaptureDeviceInput?
    private let secondaryCameraOutput = AVCaptureMovieFileOutput()
    private weak var secondaryCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var secondaryCameraPreviewView: PreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainCameraPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        secondaryCameraPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        
        mainCameraPreviewLayer = mainCameraPreviewView.videoPreviewLayer
        secondaryCameraPreviewLayer = secondaryCameraPreviewView.videoPreviewLayer
        
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
        
        // Get devices
        guard let mainCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the wide angle camera")
            return
        }
        
        var secondaryCameraDevice: AVCaptureDevice
        
        if let ultrawideCameraDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            secondaryCameraDevice = ultrawideCameraDevice
        } else if let telephotoCameraDevice = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
            secondaryCameraDevice = telephotoCameraDevice
        } else {
            print("Could not find either ultrawide or telephone camera")
            return
        }
        
//        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: nil, position: .back), let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: nil, position: .back) {
//            self.extrinsics = AVCaptureDevice.extrinsicMatrix(from: tele, to: wide)
//
//            let matrix: matrix_float4x3 = self.extrinsics!.withUnsafeBytes { $0.pointee }
//
//            print(matrix)
//        }
        
        
        // Add input
        do {
            mainCameraInput = try AVCaptureDeviceInput(device: mainCameraDevice)
            
            guard let mainCameraInput = mainCameraInput, session.canAddInput(mainCameraInput) else {
                print("Could not add wide angle camera device input")
                return
            }
            
            session.addInputWithNoConnections(mainCameraInput)
        } catch {
            print("Couldn't create wide angle camera device input: \(error)")
            return
        }
        
        do {
            secondaryCameraInput = try AVCaptureDeviceInput(device: secondaryCameraDevice)
            
            guard let secondaryCameraInput = secondaryCameraInput, session.canAddInput(secondaryCameraInput) else {
                print("Could not add secondary camera device input")
                return
            }
            
            session.addInputWithNoConnections(secondaryCameraInput)
        } catch {
            print("Couldn't create secondary camera device input: \(error)")
            return
        }

        // Add output
        guard session.canAddOutput(mainCameraOutput) else {
            print("Could not add wide-angle camera output")
            return
        }
        session.addOutputWithNoConnections(mainCameraOutput)
        
        guard session.canAddOutput(secondaryCameraOutput) else {
            print("Could not add secondary camera output")
            return
        }
        session.addOutputWithNoConnections(secondaryCameraOutput)
        
        // Setup input/output connection
        guard let mainCameraPort = mainCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: mainCameraDevice.position).first
        else {
                print("Could not obtain wide angle camera input ports")
                return
        }
        
        let secondaryCameraPort: AVCaptureInput.Port
        
        if secondaryCameraDevice.deviceType == .builtInUltraWideCamera {
            secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
                                                              sourceDeviceType: .builtInUltraWideCamera,
                                                              sourceDevicePosition: secondaryCameraDevice.position).first!
        } else if secondaryCameraDevice.deviceType == .builtInTelephotoCamera {
            secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
                                                              sourceDeviceType: .builtInTelephotoCamera,
                                                              sourceDevicePosition: secondaryCameraDevice.position).first!
        } else {
            print("Could not obtain secondary camera input ports")
            return
        }
        
        let mainCameraConnection = AVCaptureConnection(inputPorts: [mainCameraPort], output: mainCameraOutput)
        guard session.canAddConnection(mainCameraConnection) else {
            print("Cannot add wide-angle input to output")
            return
        }
        session.addConnection(mainCameraConnection)
        mainCameraConnection.videoOrientation = .landscapeRight
        
        let mainCameraAvailableVideoCodecTypes = mainCameraOutput.availableVideoCodecTypes
        if mainCameraAvailableVideoCodecTypes.contains(.h264) {
            mainCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: mainCameraConnection)
        }
        
        let secondaryCameraConnection = AVCaptureConnection(inputPorts: [secondaryCameraPort], output: secondaryCameraOutput)
        guard session.canAddConnection(secondaryCameraConnection) else {
            print("Cannot add secondary input to output")
            return
        }
        session.addConnection(secondaryCameraConnection)
        secondaryCameraConnection.videoOrientation = .landscapeRight
        
        let secondaryCameraAvailableVideoCodecTypes = mainCameraOutput.availableVideoCodecTypes
        if secondaryCameraAvailableVideoCodecTypes.contains(.h264) {
            mainCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.h264], for: mainCameraConnection)
        }
        
        // Setup input/preview connection
        guard let mainCameraPreviewLayer = mainCameraPreviewLayer else {
            return
        }
        let mainCameraPreviewLayerConnection = AVCaptureConnection(inputPort: mainCameraPort, videoPreviewLayer: mainCameraPreviewLayer)
        guard session.canAddConnection(mainCameraPreviewLayerConnection) else {
            print("Could not add a connection to the wide-angle camera video preview layer")
            return
        }
        session.addConnection(mainCameraPreviewLayerConnection)
        
        guard let secondaryCameraPreviewLayer = secondaryCameraPreviewLayer else {
            return
        }
        let secondaryCameraPreviewLayerConnection = AVCaptureConnection(inputPort: secondaryCameraPort, videoPreviewLayer: secondaryCameraPreviewLayer)
        guard session.canAddConnection(secondaryCameraPreviewLayerConnection) else {
            print("Could not add a connection to the secondary camera video preview layer")
            return
        }
        session.addConnection(secondaryCameraPreviewLayerConnection)
        
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
        
        let recordingId = Helper.getRecordingId()
        let recordingDataDirectoryPath = Helper.getRecordingDataDirectoryPath(recordingId: recordingId)
        
        // Video
        let mainVideoFilename = recordingId + "-main"
        let mainVideoPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((mainVideoFilename as NSString).appendingPathExtension("mp4")!)
        
        let secondaryVideoFilename = recordingId + "-secondary"
        let secondaryVideoPath = (recordingDataDirectoryPath as NSString).appendingPathComponent((secondaryVideoFilename as NSString).appendingPathExtension("mp4")!)
        
        self.mainCameraOutput.startRecording(to: URL(fileURLWithPath: mainVideoPath), recordingDelegate: self)
        self.secondaryCameraOutput.startRecording(to: URL(fileURLWithPath: secondaryVideoPath), recordingDelegate: self)
        
        self.isRecording = true
    }
    
    private func stopRecording() {
        
        self.mainCameraOutput.stopRecording()
        self.secondaryCameraOutput.stopRecording()
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

        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
        }
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
            self.recordButton.isEnabled = true
        }
    }
    
}
