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
class DualCameraViewController: CameraViewController {
    
    private let session = AVCaptureMultiCamSession()
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
        case multiCamNotSupported
    }
    
    private var setupResult: SessionSetupResult = .success
    
    private var extrinsics: Data?
    
    private var dualCameraInput: AVCaptureDeviceInput?
    
    //    private var cameraInput1: AVCaptureDeviceInput?
    private let wideAngleCameraOutput = AVCaptureMovieFileOutput()
    private var wideAngleFilePath: String!
    private weak var wideAngleCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var wideAngleCameraPreviewView: PreviewView!
    
    //    private var cameraInput2: AVCaptureDeviceInput?
    private let telephotoCameraOutput = AVCaptureMovieFileOutput()
    private var telephotoFilePath: String!
    private weak var telephotoCameraPreviewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var telephotoCameraPreviewView: PreviewView!
    
    private var wideAngleVideoIsReady: Bool = false
    private var telephototVideoIsReady: Bool = false
    
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
        
//        do {
//            try dualCameraDevice.lockForConfiguration()
//            dualCameraDevice.videoZoomFactor = 1.0
//            dualCameraDevice.unlockForConfiguration()
//        } catch {
//            print("Error")
//        }
        
        if let wide = AVCaptureDevice.default(.builtInWideAngleCamera, for: nil, position: .back), let tele = AVCaptureDevice.default(.builtInTelephotoCamera, for: nil, position: .back) {
            self.extrinsics = AVCaptureDevice.extrinsicMatrix(from: tele, to: wide)
            
            let matrix: matrix_float4x3 = self.extrinsics!.withUnsafeBytes { $0.pointee }
            
            print(matrix)
            
            
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
    
    override func startVideoRecording(recordingDataDirectoryPath: String, recordingId: String) {
        
//        if self.wideAngleCameraOutput.isRecording {
//            print("Error, wide-angle camera should not be recording at the moment")
//        }
//        if self.telephotoCameraOutput.isRecording {
//            print("Error, telephoto camera should not be recording at the moment")
//        }

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
        
        // Video
        let wideAngleFilename = recordingId + "-wide"
        wideAngleFilePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((wideAngleFilename as NSString).appendingPathExtension("mp4")!)
        
        let telephotoFilename = recordingId + "-tele"
        telephotoFilePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((telephotoFilename as NSString).appendingPathExtension("mp4")!)
        
        self.wideAngleCameraOutput.startRecording(to: URL(fileURLWithPath: wideAngleFilePath), recordingDelegate: self)
        self.telephotoCameraOutput.startRecording(to: URL(fileURLWithPath: telephotoFilePath), recordingDelegate: self)
    }
    
    override func stopVideoRecordingAndReturnStreamInfo() -> [CameraStreamInfo] {
        
//        if !self.wideAngleCameraOutput.isRecording {
//            print("Error, wide-angle camera should be recording but it is not")
//        }
//        if !self.telephotoCameraOutput.isRecording {
//            print("Error, telephoto camera should be recording but it is not")
//        }
        
        self.wideAngleCameraOutput.stopRecording()
        self.telephotoCameraOutput.stopRecording()
        
        while !self.wideAngleVideoIsReady || !self.telephototVideoIsReady {
            // this is a heck
            // wait until video is ready
            print("waiting for video ...")
            usleep(10000)
        }
        // get number of frames when video is ready
        let wideAngleNumFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: self.wideAngleFilePath))
        
        let wideAngleStreamInfo = CameraStreamInfo(id: "color_back_1", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, num_frames: wideAngleNumFrames, resolution: [], focal_length: [], principal_point: [], extrinsics_matrix: nil)
        
        // get number of frames when video is ready
        let telephotoNumFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: self.telephotoFilePath))
        
        let telephotoStreamInfo = CameraStreamInfo(id: "color_back_2", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, num_frames: telephotoNumFrames, resolution: [], focal_length: [], principal_point: [], extrinsics_matrix: nil)
        
        wideAngleVideoIsReady = false
        telephototVideoIsReady = false
        
        return [wideAngleStreamInfo, telephotoStreamInfo]
    }
    
    override func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        super.fileOutput(output, didFinishRecordingTo: outputFileURL, from: connections, error: error)
        
        if outputFileURL.absoluteString == URL(fileURLWithPath: wideAngleFilePath).absoluteString {
            wideAngleVideoIsReady = true
        } else if outputFileURL.absoluteString == URL(fileURLWithPath: telephotoFilePath).absoluteString {
            telephototVideoIsReady = true
        }
    }
}
