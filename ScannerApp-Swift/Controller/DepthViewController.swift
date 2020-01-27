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

    
    
    private var videoTrackSourceFormatDescription: CMFormatDescription?
    private var isRecording = false
    
    
    
    
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
//        let videoRect = videoOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
        let depthRect = depthOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
        
//        scale =
//            max(videoRect.width, videoRect.height) /
//            max(depthRect.width, depthRect.height)
        
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
    
    
    
    
    
    func startRecording() {
        
    }
    
    
    
    
    
    
}

// MARK: - Capture Video Data Delegate Methods
extension DepthViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            processVideoSampleBuffer(sampleBuffer, fromOutput: videoDataOutput)
        } else {
            print("Potential error...")
        }
        
    }
    
    private func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        if videoTrackSourceFormatDescription == nil {
            videoTrackSourceFormatDescription = CMSampleBufferGetFormatDescription( sampleBuffer )
        }

        // Determine:
        // - which camera the sample buffer came from
        // - if the sample buffer is for the PiP
//        var fullScreenSampleBuffer: CMSampleBuffer?
//        var pipSampleBuffer: CMSampleBuffer?
//
//        if pipDevicePosition == .back && videoDataOutput == backCameraVideoDataOutput {
//            pipSampleBuffer = sampleBuffer
//        } else if pipDevicePosition == .back && videoDataOutput == frontCameraVideoDataOutput {
//            fullScreenSampleBuffer = sampleBuffer
//        } else if pipDevicePosition == .front && videoDataOutput == backCameraVideoDataOutput {
//            fullScreenSampleBuffer = sampleBuffer
//        } else if pipDevicePosition == .front && videoDataOutput == frontCameraVideoDataOutput {
//            pipSampleBuffer = sampleBuffer
//        }
//
//        if let fullScreenSampleBuffer = fullScreenSampleBuffer {
//            processFullScreenSampleBuffer(fullScreenSampleBuffer)
//        }
//
//        if let pipSampleBuffer = pipSampleBuffer {
//            processPiPSampleBuffer(pipSampleBuffer)
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
        
        
        
//        let depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        

        
        // save depthMap for testing
//        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
//        let path = (documentsDirectory as NSString).appendingPathComponent(("test" as NSString).appendingPathExtension("depth")!)
//
////        let data = UIImage.pngData(UIImage(ciImage: depthMap))
//        let data = UIImage(ciImage: depthMap).pngData()
//
//        do {
//            try data?.write(to: URL(fileURLWithPath: path))
//        } catch {
//            print("......")
//        }
        
        
//        DispatchQueue.main.async { [weak self] in
//            self?.depthMap = depthMap
//        }
        
        
        
        
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = (documentsDirectory as NSString).appendingPathComponent(("test" as NSString).appendingPathExtension("depth")!)
        
        
        
        if isRecording {
            guard let depthVideoSampleBuffer =
                createVideoSampleBufferWithPixelBuffer(pixelBuffer, presentationTime: timestamp) else {
                    print("Error: Unable to create sample buffer from pixelbuffer")
                    return
            }
            
            recordVideo(sampleBuffer: depthVideoSampleBuffer)
        }
        
        
        
        
        
    }
    
    
    
    
    private func recordVideo(sampleBuffer: CMSampleBuffer) {
        
    }
    
    
    
    
    private func createVideoSampleBufferWithPixelBuffer(_ pixelBuffer: CVPixelBuffer, presentationTime: CMTime) -> CMSampleBuffer? {
        guard let videoTrackSourceFormatDescription = videoTrackSourceFormatDescription else {
            return nil
        }
        
        
        
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime, decodeTimeStamp: .invalid)
        
        let err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: videoTrackSourceFormatDescription,
                                                     sampleTiming: &timingInfo,
                                                     sampleBufferOut: &sampleBuffer)
        if sampleBuffer == nil {
            print("Error: Sample buffer creation failed (error code: \(err))")
        }
        
        return sampleBuffer
    }
    
}

