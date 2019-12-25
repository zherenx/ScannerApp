//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import CoreMotion
import UIKit

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    private let sessionQueue = DispatchQueue(label: "session queue")
//    private let motionQueue = DispatchQueue(label: "motion queue")
    private let motionQueue = OperationQueue()
    
    private let session = AVCaptureSession()
//    private let photoOutput = AVCapturePhotoOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private let motionManager = CMMotionManager()
    
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previewView.videoPreviewLayer.session = self.session
        
        // TODO: authorization check
        
        self.configurateSession()
        self.setupIMU()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.sessionQueue.async {
            self.session.stopRunning()
        }
        
        super.viewWillDisappear(animated)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    private func configurateSession() {
        self.session.beginConfiguration()
        
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

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
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
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
//            setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
        
        if self.session.canAddOutput(self.movieFileOutput) {
//            self.session.beginConfiguration()
            self.session.addOutput(self.movieFileOutput)
            self.session.sessionPreset = .high
            if let connection = self.movieFileOutput.connection(with: .video) {
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
        
        self.session.commitConfiguration()
        
    }
    
    private func setupIMU() {
        self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        self.motionQueue.maxConcurrentOperationCount = 1
        
//        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (rawData, error) in
//            if let data = rawData {
////                print(data)
//                MotionDataProcessor.processDeviceMotion(deviceMotion: data)
//            } else {
//                print("there is some problem with motion data")
//            }
//        }
    }
    
//    private func processDeviceMotion() {
//
//    }
    
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
    
//        guard let movieFileOutput = self.movieFileOutput else {
//            return
//        }
        
        self.recordButton.isEnabled = false
        self.stopButton.isEnabled = true
        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        
        
        
        self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) { (rawData, error) in
            if let data = rawData {
                print(data)
//                MotionDataProcessor.processDeviceMotion(deviceMotion: data)
            } else {
                print("there is some problem with motion data")
            }
        }
        
        
        
        
        self.sessionQueue.async {
            if !self.movieFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = self.movieFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }
                
                let outputFileName = NSUUID().uuidString
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let outputFilePath = (documentsPath as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                
                self.motionManager.startDeviceMotionUpdates(to: self.motionQueue) { (rawData, error) in
                    if let data = rawData {
//                        print(data)
                        MotionDataProcessor.processDeviceMotion(deviceMotion: data)
                    } else {
                        print("there is some problem with motion data")
                    }
                }
                
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                self.movieFileOutput.stopRecording()
                self.motionManager.stopDeviceMotionUpdates()
            }
        }
        
    }
    
    @IBAction private func stopButtonTapped(_ sender: Any) {
        // TODO
        // I probably do not need this
        
        // testing for motion
        self.motionManager.stopDeviceMotionUpdates()
        
    }
    
    /// - Tag: DidStartRecording
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Enable the Record button to let the user stop recording.
        DispatchQueue.main.async {
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.isEnabled = true
//            self.recordButton.setImage(#imageLiteral(resourceName: "CaptureStop"), for: [])
        }
    }
    
    /// - Tag: DidFinishRecording
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
//            let path = outputFileURL.path
//            if FileManager.default.fileExists(atPath: path) {
//                do {
//                    try FileManager.default.removeItem(atPath: path)
//                } catch {
//                    print("Could not remove file at url: \(outputFileURL)")
//                }
//            }
            
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
        
//        if success {
//            // Check the authorization status.
//            PHPhotoLibrary.requestAuthorization { status in
//                if status == .authorized {
//                    // Save the movie file to the photo library and cleanup.
//                    PHPhotoLibrary.shared().performChanges({
//                        let options = PHAssetResourceCreationOptions()
//                        options.shouldMoveFile = true
//                        let creationRequest = PHAssetCreationRequest.forAsset()
//                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
//                    }, completionHandler: { success, error in
//                        if !success {
//                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
//                        }
//                        cleanup()
//                    }
//                    )
//                } else {
//                    cleanup()
//                }
//            }
//        } else {
//            cleanup()
//        }
        
        cleanup()
        
        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            // Only enable the ability to change camera if the device has more than one camera.
//            self.cameraButton.isEnabled = self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
            
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.isEnabled = true
            
//            self.captureModeControl.isEnabled = true
//            self.recordButton.setImage(#imageLiteral(resourceName: "CaptureVideo"), for: [])
        }
    }
}
