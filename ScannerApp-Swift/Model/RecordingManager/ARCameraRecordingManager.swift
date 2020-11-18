//
//  ARCameraRecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-17.
//  Copyright © 2020 jx16. All rights reserved.
//

import ARKit

@available(iOS 14.0, *)
class ARCameraRecordingManager: NSObject {
    
    private let sessionQueue = DispatchQueue(label: "ar camera recording queue")
    
    private let session = ARSession()
    
    private let depthRecorder = DepthRecorder()
    private let confidenceMapRecorder = ConfidenceMapRecorder()
    private let rgbRecorder = RGBRecorder(videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: 1440), AVVideoWidthKey: NSNumber(value: 1920)])
    private let cameraInfoRecorder = CameraInfoRecorder()
    
    private var numFrames: Int = 0
    private var dirUrl: URL!
    private var recordingId: String!
    private var isRecording: Bool = false
    
    private let locationManager = CLLocationManager()
    private var gpsLocation: [Double] = []
    
    private var cameraIntrinsic: simd_float3x3?
    private var colorFrameResolution: [Int] = []
    private var depthFrameResolution: [Int] = []
    private var frequency: Int?
    
    override init() {
        super.init()
        
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    // TODO: think about better name?
    private func configureSession() {
        session.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        session.run(configuration)
        
        let videoFormat = configuration.videoFormat
        frequency = videoFormat.framesPerSecond
        let imageResolution = videoFormat.imageResolution
        colorFrameResolution = [Int(imageResolution.height), Int(imageResolution.width)]
    }
}

@available(iOS 14.0, *)
extension ARCameraRecordingManager: RecordingManager {
    
    func startRecording() {
        
        sessionQueue.async { [self] in
            
            gpsLocation = getGpsLocation()
            
            numFrames = 0
            
            if let currentFrame = session.currentFrame {
                cameraIntrinsic = currentFrame.camera.intrinsics
                
                // get depth resolution
                if let depthData = currentFrame.sceneDepth {
                    
                    let depthMap: CVPixelBuffer = depthData.depthMap
                    let height = CVPixelBufferGetHeight(depthMap)
                    let width = CVPixelBufferGetWidth(depthMap)
                    
                    depthFrameResolution = [height, width]
                    
                } else {
                    print("Unable to get depth resolution.")
                }
                
            }
            
            print("pre1 count: \(numFrames)")
            
            recordingId = Helper.getRecordingId()
            dirUrl = URL(fileURLWithPath: Helper.getRecordingDataDirectoryPath(recordingId: recordingId))
            
            depthRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
            confidenceMapRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
            rgbRecorder.prepareForRecording(dirPath: dirUrl.path, filenameWithoutExt: recordingId)
            cameraInfoRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
            
            isRecording = true
            
            print("pre2 count: \(numFrames)")
        }
        
    }
    
    func finishRecordingAndReturnStreamInfo() -> [StreamInfo] {
        
        sessionQueue.sync { [self] in
            
            print("post count: \(numFrames)")
            
            isRecording = false
            
            depthRecorder.finishRecording()
            confidenceMapRecorder.finishRecording()
            rgbRecorder.finishRecording()
            cameraInfoRecorder.finishRecording()
            
        }
        
        return getStreamInfo()
    }
    
    func getSession() -> NSObject {
        return session
    }
    
    private func getStreamInfo() -> [StreamInfo]{
        
        let cameraIntrinsicArray = [cameraIntrinsic!.columns.0.x, cameraIntrinsic!.columns.0.y, cameraIntrinsic!.columns.0.z,
                                    cameraIntrinsic!.columns.1.x, cameraIntrinsic!.columns.1.y, cameraIntrinsic!.columns.1.z,
                                    cameraIntrinsic!.columns.2.x, cameraIntrinsic!.columns.2.y, cameraIntrinsic!.columns.2.z]
        let rgbStreamInfo = CameraStreamInfo(id: "color_back_1", type: "color_camera", encoding: "h264", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "mp4", resolution: colorFrameResolution, intrinsics: cameraIntrinsicArray, extrinsics: nil)
        let depthStreamInfo = CameraStreamInfo(id: "depth_back_1", type: "lidar_sensor", encoding: "float16_zlib", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "depth.zlib", resolution: depthFrameResolution, intrinsics: nil, extrinsics: nil)
        let confidenceMapStreamInfo = StreamInfo(id: "confidence_map", type: "confidence_map", encoding: "uint8_zlib", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "confidence.zlib")
        let cameraInfoStreamInfo = StreamInfo(id: "camera_info_color_back_1", type: "camera_info", encoding: "jsonl", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "jsonl")
        
        return [rgbStreamInfo, depthStreamInfo, confidenceMapStreamInfo, cameraInfoStreamInfo]
    }
    
    // intended to be moved to Helper
    // this assume gps authorization has been done previously
    private func getGpsLocation() -> [Double] {
        let locationManager = CLLocationManager()
//        locationManager.requestWhenInUseAuthorization()
        
        var gpsLocation: [Double] = []
        
        if (CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways) {
            if let coordinate = locationManager.location?.coordinate {
                gpsLocation = [coordinate.latitude, coordinate.longitude]
            }
        }
        
        return gpsLocation
    }
}

@available(iOS 14.0, *)
extension ARCameraRecordingManager: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
//        print("Got frame update.")
        
        if !isRecording {
            return
        }
        
        guard let depthData = frame.sceneDepth else {
            print("Failed to acquire depth data.")
            return
        }

        let depthMap: CVPixelBuffer = depthData.depthMap
        let colorImage: CVPixelBuffer = frame.capturedImage
        
        guard let confidenceMap = depthData.confidenceMap else {
            print("Failed to get confidenceMap.")
            return
        }

        let timestamp: CMTime = CMTime(seconds: frame.timestamp, preferredTimescale: 1_000_000_000)

        print("**** @Controller: depth \(numFrames) ****")
        depthRecorder.update(buffer: depthMap)

        print("**** @Controller: confidence \(numFrames) ****")
        confidenceMapRecorder.update(buffer: confidenceMap)
        
        print("**** @Controller: color \(numFrames) ****")
        rgbRecorder.update(buffer: colorImage, timestamp: timestamp)
        print()
    
        let currentCameraInfo = CameraInfo(timestamp: frame.timestamp,
                                           transform: frame.camera.transform,
                                           eulerAngles: frame.camera.eulerAngles,
                                           exposureDuration: frame.camera.exposureDuration)
        cameraInfoRecorder.update(cameraInfo: currentCameraInfo)
        
        numFrames += 1
    }
}

