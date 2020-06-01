//
//  SingleCameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-06-01.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation
import UIKit

class SingleCameraViewController: CameraViewController {

    private let session = AVCaptureSession()

    private var defaultVideoDevice: AVCaptureDevice?
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var movieFilePath: String!
    
    private var colorResolution: [Int]!
    private var focalLength: [Float]!
    private var principalPoint: [Float]!

    private var videoIsReady: Bool = false // this is a heck, consider improve it

    @IBOutlet private weak var previewView: PreviewView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.previewView.videoPreviewLayer.session = self.session

        // TODO: order of these function calls might matter, consider improve on this
        self.configurateSession()
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

    private func configurateSession() {
        self.session.beginConfiguration()

        do {
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                return
            }

            do {
                try videoDevice.lockForConfiguration()

                let targetFrameDuration = CMTimeMake(value: 1, timescale: Int32(Constants.Sensor.Camera.frequency))
                videoDevice.activeVideoMaxFrameDuration = targetFrameDuration
                videoDevice.activeVideoMinFrameDuration = targetFrameDuration

                videoDevice.unlockForConfiguration()
            } catch {
                print("Error configurating video device")
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
            } else {
                print("Couldn't add video device input to the session.")
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            self.session.commitConfiguration()
            return
        }

        if self.session.canAddOutput(self.movieFileOutput) {
            self.session.addOutput(self.movieFileOutput)

            //            self.session.sessionPreset = .photo
            self.session.sessionPreset = .hd1920x1080

            if let connection = self.movieFileOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }

                connection.videoOrientation = .landscapeRight
            }
        }

        let videoFormatDescription = defaultVideoDevice!.activeFormat.formatDescription
        let dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription)

        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        colorResolution = [width, height]

        // TODO: calculate these
        let fov = defaultVideoDevice!.activeFormat.videoFieldOfView
        let aspect = Float(width) / Float(height)
        let t = tan(0.5 * fov)

        //            float fx = 0.5f * width / t;
        //            float fy = 0.5f * height / t * aspect;
        //
        //            float mx = (float)(width - 1.0f) / 2.0f;
        //            float my = (float)(height - 1.0f) / 2.0f;

        let fx = 0.5 * Float(width) / t
        let fy = 0.5 * Float(height) / t

        let mx = Float(width - 1) / 2.0
        let my = Float(height - 1) / 2.0

        focalLength = [fx, fy]
        principalPoint = [mx, my]

        //        print(fov)
        //        print(aspect)
        //        print(width)
        //        print(height)
        //        print(focalLength)
        //        print(principalPoint)

        self.session.commitConfiguration()

    }
    
    override func startVideoRecording(recordingDataDirectoryPath: String, recordingId: String) {
        let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
        movieFileOutputConnection?.videoOrientation = .landscapeRight
        
        self.movieFilePath = (recordingDataDirectoryPath as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension(Constants.Sensor.Camera.fileExtension)!)
        self.movieFileOutput.startRecording(to: URL(fileURLWithPath: self.movieFilePath), recordingDelegate: self)
    }
    
    override func stopVideoRecordingAndReturnStreamInfo() -> [CameraStreamInfo] {
        self.movieFileOutput.stopRecording()
        
        while !self.videoIsReady {
            // this is a heck
            // wait until video is ready
            print("waiting for video ...")
            usleep(10000)
        }
        // get number of frames when video is ready
        let numColorFrames = VideoHelper.getNumberOfFrames(videoUrl: URL(fileURLWithPath: self.movieFilePath))
    
        let cameraStreamInfo = CameraStreamInfo(id: "color_back_1", type: Constants.Sensor.Camera.type, encoding: Constants.EncodingCode.h264, frequency: Constants.Sensor.Camera.frequency, num_frames: numColorFrames, resolution: self.colorResolution, focal_length: self.focalLength, principal_point: self.principalPoint, extrinsics_matrix: nil)
        
        videoIsReady = false
        
        return [cameraStreamInfo]
    }

    override func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        super.fileOutput(output, didFinishRecordingTo: outputFileURL, from: connections, error: error)

        videoIsReady = true
    }


}
