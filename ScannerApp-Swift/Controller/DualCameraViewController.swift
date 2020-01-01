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
        let telephotoCameraConnection = AVCaptureConnection(inputPorts: [telePort], output: telephotoCameraOutput)
        
        guard session.canAddConnection(wideAngleCameraConnection) else {
            print("Cannot add wide-angle input to output")
            setupResult = .configurationFailed
            return
        }
        
        guard session.canAddConnection(telephotoCameraConnection) else {
            print("Cannot add telephoto input to output")
            setupResult = .configurationFailed
            return
        }
        
        session.addConnection(wideAngleCameraConnection)
        session.addConnection(telephotoCameraConnection)
        
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
        
}
