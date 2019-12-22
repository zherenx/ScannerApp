//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import UIKit

class CameraViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
//        previewView.session = session
        self.previewView.videoPreviewLayer.session = self.session
        
        // TODO: authorization check
        
        configurateSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let session = AVCaptureSession()
    
    @IBOutlet private weak var previewView: PreviewView!
    
//    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    
    
    private func configurateSession() {
        session.beginConfiguration()
        
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
//                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
//                self.videoDeviceInput = videoDeviceInput

//                DispatchQueue.main.async {
//                    /*
//                     Dispatch video streaming to the main queue because AVCaptureVideoPreviewLayer is the backing layer for PreviewView.
//                     You can manipulate UIView only on the main thread.
//                     Note: As an exception to the above rule, it's not necessary to serialize video orientation changes
//                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
//
//                     Use the window scene's orientation as the initial video orientation. Subsequent orientation changes are
//                     handled by CameraViewController.viewWillTransition(to:with:).
//                     */
//                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
//                    if self.windowOrientation != .unknown {
//                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
//                            initialVideoOrientation = videoOrientation
//                        }
//                    }
//
//                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
//                }
            } else {
                print("Couldn't add video device input to the session.")
//                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
//            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
//        if session.canAddOutput(photoOutput) {
//            session.addOutput(photoOutput)
//
//            photoOutput.isHighResolutionCaptureEnabled = true
//            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
//            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
//            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
//            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
//            selectedSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
//            photoOutput.maxPhotoQualityPrioritization = .quality
//            livePhotoMode = photoOutput.isLivePhotoCaptureSupported ? .on : .off
//            depthDataDeliveryMode = photoOutput.isDepthDataDeliverySupported ? .on : .off
//            portraitEffectsMatteDeliveryMode = photoOutput.isPortraitEffectsMatteDeliverySupported ? .on : .off
//            photoQualityPrioritizationMode = .balanced
//
//        } else {
//            print("Could not add photo output to the session")
//            setupResult = .configurationFailed
//            session.commitConfiguration()
//            return
//        }
        
        if self.session.canAddOutput(movieFileOutput) {
//            self.session.beginConfiguration()
            self.session.addOutput(movieFileOutput)
            self.session.sessionPreset = .high
            if let connection = movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
//            self.session.commitConfiguration()
            
//            DispatchQueue.main.async {
//                captureModeControl.isEnabled = true
//            }
//
//            self.movieFileOutput = movieFileOutput
//
//            DispatchQueue.main.async {
//                self.recordButton.isEnabled = true
//
//                /*
//                 For photo captures during movie recording, Speed quality photo processing is prioritized
//                 to avoid frame drops during recording.
//                 */
//                self.photoQualityPrioritizationSegControl.selectedSegmentIndex = 0
//                self.photoQualityPrioritizationSegControl.sendActions(for: UIControl.Event.valueChanged)
//            }
        }
        
        session.commitConfiguration()
        
        
    }
    

}
