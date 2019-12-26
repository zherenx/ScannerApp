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
    
    private var dualCameraInput: AVCaptureDeviceInput?
    
//    private var cameraInput1: AVCaptureDeviceInput?
    
    private let wideAngleCameraOutput = AVCaptureMovieFileOutput()
    
    private weak var cameraVideoPreviewLayer1: AVCaptureVideoPreviewLayer?
    
//    private var cameraInput2: AVCaptureDeviceInput?

    private let telephotoCameraOutput = AVCaptureMovieFileOutput()
    
    private weak var cameraVideoPreviewLayer2: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO:
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // TODO:
        super.viewWillDisappear(animated)
    }
    
    private func configureSession() {
        //        guard setupResult == .success else { return }
        
        //        guard AVCaptureMultiCamSession.isMultiCamSupported else {
        //            print("MultiCam not supported on this device")
        //            setupResult = .multiCamNotSupported
        //            return
        //        }
        
        // When using AVCaptureMultiCamSession, it is best to manually add connections from AVCaptureInputs to AVCaptureOutputs
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
            return
        }
        
        do {
            dualCameraInput = try AVCaptureDeviceInput(device: dualCameraDevice)
            
            guard let dualCameraInput = dualCameraInput, session.canAddInput(dualCameraInput) else {
                    print("Could not add dual camera device input")
                    return
            }
            
            session.addInputWithNoConnections(dualCameraInput)
        } catch {
            print("Couldn't create dual camera device input: \(error)")
//            setupResult = .configurationFailed
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
        guard let widePort = dualCameraInput!.ports(for: .video,
                                                   sourceDeviceType: .builtInWideAngleCamera,
                                                   sourceDevicePosition: dualCameraDevice.position).first,
            let telePort = dualCameraInput!.ports(for: .video,
                                                 sourceDeviceType: .builtInTelephotoCamera,
                                                 sourceDevicePosition: dualCameraDevice.position).first
            else {
                print("Could not obtain wide and telephoto camera input ports")
                return
        }
        
        let wideAngelCameraConnection = AVCaptureConnection(inputPorts: [widePort], output: wideAngleCameraOutput)
        let telephotoCameraConnection = AVCaptureConnection(inputPorts: [telePort], output: telephotoCameraOutput)
        
        guard session.canAddConnection(wideAngelCameraConnection) else {
            print("Cannot add wide-angle input to output")
            return
        }
        
        guard session.canAddConnection(telephotoCameraConnection) else {
            print("Cannot add telephoto input to output")
            return
        }
        
        session.addConnection(wideAngelCameraConnection)
        session.addConnection(telephotoCameraConnection)
        
    }
        
}
