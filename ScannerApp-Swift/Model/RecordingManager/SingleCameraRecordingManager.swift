//
//  SingleCameraRecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-18.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation
import CoreLocation

class SingleCameraRecordingManager: NSObject {
    
    private let sessionQueue = DispatchQueue(label: "single camera recording queue")
    
    private let session = AVCaptureSession()

    private let motionManager = MotionManager()
    
//    private var dirUrl: URL!
    private var recordingId: String!
    private var movieFilePath: String!
    private var metadataPath: String!
    var isRecording: Bool = false
    
    private var videoIsReady: Bool = false // this is a heck, consider improve it
    
    private var defaultVideoDevice: AVCaptureDevice?

    private let movieFileOutput = AVCaptureMovieFileOutput()
    
//    private var backgroundRecordingID: UIBackgroundTaskIdentifier?
    
    private let locationManager = CLLocationManager()
    private var gpsLocation: [Double]!
    
    private var colorResolution: [Int]!
    private var cameraIntrinsicArray: [Float]?
    
    private var username: String?
    private var sceneDescription: String?
    private var sceneType: String?
    
    override init() {
        super.init()
        
        locationManager.requestWhenInUseAuthorization()
        
        sessionQueue.async {
            self.configureSession()
            
            self.session.startRunning()
        }
    }
    
    private func configureSession() {
        
    }

}

extension SingleCameraRecordingManager: RecordingManager {
    
    func getSession() -> NSObject {
        return session
    }
    
    func startRecording(username: String, sceneDescription: String, sceneType: String) {
        
    }
    
    func stopRecording() {
        
    }
    
}

extension SingleCameraRecordingManager: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
}
