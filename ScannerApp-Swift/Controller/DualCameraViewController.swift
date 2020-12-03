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
        
        guard let mainCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find the wide angle camera")
            return
        }
        
        guard let secondaryCameraDevice = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) else {
            print("Could not find the ultrawide camera")
            return
        }
        
        
        
//        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: nil, position: .back), let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: nil, position: .back) {
//            self.extrinsics = AVCaptureDevice.extrinsicMatrix(from: tele, to: wide)
//
//            let matrix: matrix_float4x3 = self.extrinsics!.withUnsafeBytes { $0.pointee }
//
//            print(matrix)
//        }
        
        
        
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
        
        
        
        
        // setup output
        guard session.canAddOutput(mainCameraOutput) else {
            print("Could not add wide-angle camera output")
            return
        }
        session.addOutputWithNoConnections(mainCameraOutput)
        
        
        // TODO: check setting 
//        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        
        
        guard session.canAddOutput(secondaryCameraOutput) else {
            print("Could not add secondary camera output")
            return
        }
        session.addOutputWithNoConnections(secondaryCameraOutput)
        
        // setup connections
        guard let mainCameraPort = mainCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: mainCameraDevice.position).first
        else {
                print("Could not obtain wide angle camera input ports")
                return
        }
//        guard let secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
//                                                   sourceDeviceType: .builtInTelephotoCamera,
//                                                   sourceDevicePosition: telephotoDevice.position).first
//        else {
//            print("Could not obtain telephoto camera input ports")
//            return
//        }
        guard let secondaryCameraPort = secondaryCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInUltraWideCamera,
                                                   sourceDevicePosition: secondaryCameraDevice.position).first
        else {
            print("Could not obtain ultrawide camera input ports")
            return
        }
        
        let mainCameraConnection = AVCaptureConnection(inputPorts: [mainCameraPort], output: mainCameraOutput)
        guard session.canAddConnection(mainCameraConnection) else {
            print("Cannot add wide-angle input to output")
            return
        }
        session.addConnection(mainCameraConnection)
//        mainCameraConnection.videoOrientation = .portrait
        mainCameraConnection.videoOrientation = .landscapeRight
        
        let secondaryCameraConnection = AVCaptureConnection(inputPorts: [secondaryCameraPort], output: secondaryCameraOutput)
        guard session.canAddConnection(secondaryCameraConnection) else {
            print("Cannot add secondary input to output")
            return
        }
        session.addConnection(secondaryCameraConnection)
//        secondaryCameraConnection.videoOrientation = .portrait
        secondaryCameraConnection.videoOrientation = .landscapeRight
        
        // connect to preview layers
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
        
//        if self.mainCameraOutput.isRecording {
//            print("Error, wide-angle camera should not be recording at the moment")
//        }
//        if self.secondaryCameraOutput.isRecording {
//            print("Error, secondary camera should not be recording at the moment")
//        }
        
        let mainCameraOutputConnection = self.mainCameraOutput.connection(with: .video)
        mainCameraOutputConnection?.videoOrientation = .landscapeRight
        //                let wideAngleAvailableVideoCodecTypes = self.mainCameraOutput.availableVideoCodecTypes
        //                if wideAngleAvailableVideoCodecTypes.contains(.hevc) {
        //                    self.mainCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: wideAngleOutputConnection!)
        //                }
        
        let secondaryCameraOutputConnection = self.secondaryCameraOutput.connection(with: .video)
        secondaryCameraOutputConnection?.videoOrientation = .landscapeRight
        //                let telephotoAvailableVideoCodecTypes = self.secondaryCameraOutput.availableVideoCodecTypes
        //                if telephotoAvailableVideoCodecTypes.contains(.hevc) {
        //                    self.secondaryCameraOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: telephoteOutputConnection!)
        //                }
        
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
        
//        if !self.mainCameraOutput.isRecording {
//            print("Error, wide-angle camera should be recording but it is not")
//        }
//        if !self.secondaryCameraOutput.isRecording {
//            print("Error, secondary camera should be recording but it is not")
//        }
        
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
