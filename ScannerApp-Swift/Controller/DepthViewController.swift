//
//  DepthViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-01-25.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit
import AVFoundation

import CoreImage

class DepthViewController: UIViewController {
    
    
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet weak var previewView: PreviewView!
    
    
    
    let session = AVCaptureSession()
    let dataOutputQueue = DispatchQueue(label: "video data queue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .workItem)
    
    
    
    var scale: CGFloat = 0.0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewView.videoPreviewLayer.session = self.session
        previewLayer = previewView.videoPreviewLayer

        configureCaptureSession()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.dataOutputQueue.async {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.dataOutputQueue.async {
            self.session.stopRunning()
        }
        
        super.viewWillDisappear(animated)
    }
    
}

// MARK: - Helper Methods
extension DepthViewController {
    func configureCaptureSession() {
        guard let camera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .unspecified) else {
            fatalError("No depth video camera available")
        }
        
        session.sessionPreset = .photo
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            session.addInput(cameraInput)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        session.addOutput(videoOutput)
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        let depthOutput = AVCaptureDepthDataOutput()
        depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
        depthOutput.isFilteringEnabled = true
        session.addOutput(depthOutput)
        
        let depthConnection = depthOutput.connection(with: .depthData)
        depthConnection?.videoOrientation = .portrait
        
        let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let videoRect = videoOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
        let depthRect = depthOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
        
        scale =
            max(videoRect.width, videoRect.height) /
            max(depthRect.width, depthRect.height)
        
        do {
            try camera.lockForConfiguration()
            
            if let format = camera.activeDepthDataFormat,
                let range = format.videoSupportedFrameRateRanges.first  {
                camera.activeVideoMinFrameDuration = range.minFrameDuration
            }
            
            camera.unlockForConfiguration()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

// MARK: - Capture Video Data Delegate Methods
extension DepthViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let image = CIImage(cvPixelBuffer: pixelBuffer!)
        
        let previewImage: CIImage
        
        previewImage = image
//        previewImage = depthMap ?? image
        
        
        let displayImage = UIImage(ciImage: previewImage)
//        DispatchQueue.main.async { [weak self] in
//            self?.previewView.image = displayImage
//        }
    }
}

// MARK: - Capture Depth Data Delegate Methods
extension DepthViewController: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput,
                         didOutput depthData: AVDepthData,
                         timestamp: CMTime,
                         connection: AVCaptureConnection) {
        
        
        
        
        print("hello world")
        
        
        
        
        
        var convertedDepth: AVDepthData
        
        let depthDataType = kCVPixelFormatType_DisparityFloat32
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }
        
        
        let pixelBuffer = convertedDepth.depthDataMap
//        pixelBuffer.clamp()
        
        
        let depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        
        
        
        
        
        // save depthMap for testing
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = (documentsDirectory as NSString).appendingPathComponent(("test" as NSString).appendingPathExtension("depth")!)
        
//        let data = UIImage.pngData(UIImage(ciImage: depthMap))
        let data = UIImage(ciImage: depthMap).pngData()
        
        
        do {
            
            try data?.write(to: URL(fileURLWithPath: path))
            
            
//            try CIContext.init().writePNGRepresentation(of: depthMap, to: URL(fileURLWithPath: path), format: .A8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [CIImageRepresentationOption : Any]())
        } catch {
            print("......")
        }
        
        
        
        
        
        
//        DispatchQueue.main.async { [weak self] in
//            self?.depthMap = depthMap
//        }
    }
}

