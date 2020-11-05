//
//  ViewController.swift
//  LiDARDepth
//
//  Created by Zheren Xiao on 2020-09-13.
//  Copyright © 2020 jx16. All rights reserved.
//

import ARKit
import RealityKit
import UIKit

protocol CameraViewControllerPopUpViewDelegate: class {
    func startRecording()
    func dismissPopUpView()
}

@available(iOS 14.0, *)
class ARCameraViewController: UIViewController, CameraViewControllerPopUpViewDelegate {
    
    let session = ARSession()
    
    let depthRecorder = DepthRecorder()
    let confidenceMapRecorder = ConfidenceMapRecorder()
    let rgbRecorder = RGBRecorder(videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: 1440), AVVideoWidthKey: NSNumber(value: 1920)])
    let cameraInfoRecorder = CameraInfoRecorder()
    
    var numFrames: Int = 0
    var dirUrl: URL!
    var recordingId: String!
    var isRecording: Bool = false
    
    let locationManager = CLLocationManager()
    var gpsLocation: [Double] = []
    
    var cameraIntrinsic: simd_float3x3?
    var colorFrameResolution: [Int] = []
    var depthFrameResolution: [Int] = []
    var frequency: Int?
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var recordButton: UIButton!
    
    var popUpView: PopUpView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupPopUpView()
        
//        arView.session.delegate = self
        session.delegate = self
        arView.session = session

        locationManager.requestWhenInUseAuthorization()
        
        // dismiss keyboard when tap elsewhere
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    private func setupPopUpView() {
        
        popUpView = PopUpView()
        popUpView.delegate = self
        
        view.addSubview(popUpView)
        
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popUpView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
        
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        session.run(configuration)
//        arView.session.run(configuration)
        
        let videoFormat = configuration.videoFormat
        frequency = videoFormat.framesPerSecond
        let imageResolution = videoFormat.imageResolution
        colorFrameResolution = [Int(imageResolution.height), Int(imageResolution.width)]
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        if isRecording {
            stopRecording()
        } else {
            DispatchQueue.main.async {
                self.recordButton.isEnabled = false
                self.popUpView.isHidden = false
            }
        }
    }
    
    func startRecording() {
        
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            
            self.recordButton.setTitle("Stop", for: .normal)
            self.recordButton.backgroundColor = .systemRed
            self.recordButton.isEnabled = true
        }
        
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
    
    func dismissPopUpView() {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            self.recordButton.isEnabled = true
        }
    }
    
    func stopRecording() {
        print("post count: \(numFrames)")
        
        isRecording = false
        
        depthRecorder.finishRecording()
        confidenceMapRecorder.finishRecording()
        rgbRecorder.finishRecording()
        cameraInfoRecorder.finishRecording()
        
        saveMetadata()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
        }
    }
    
    private func saveMetadata() {
        let username = popUpView.firstName + " " + popUpView.lastName
        let sceneType = popUpView.sceneTypes[popUpView.sceneTypeIndex]
        
        let cameraIntrinsicArray = [cameraIntrinsic!.columns.0.x, cameraIntrinsic!.columns.0.y, cameraIntrinsic!.columns.0.z,
                                    cameraIntrinsic!.columns.1.x, cameraIntrinsic!.columns.1.y, cameraIntrinsic!.columns.1.z,
                                    cameraIntrinsic!.columns.2.x, cameraIntrinsic!.columns.2.y, cameraIntrinsic!.columns.2.z]
        let rgbStreamInfo = CameraStreamInfo(id: "color_back_1", type: "color_camera", encoding: "h264", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "mp4", resolution: colorFrameResolution, intrinsics: cameraIntrinsicArray, extrinsics: nil)
        let depthStreamInfo = CameraStreamInfo(id: "depth_back_1", type: "lidar_sensor", encoding: "float16_zlib", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "depth.zlib", resolution: depthFrameResolution, intrinsics: nil, extrinsics: nil)
        let confidenceMapStreamInfo = StreamInfo(id: "confidence_map", type: "confidence_map", encoding: "uint8_zlib", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "confidence.zlib")
        let cameraInfoStreamInfo = StreamInfo(id: "camera_info_color_back_1", type: "camera_info", encoding: "jsonl", frequency: frequency ?? 0, numberOfFrames: numFrames, fileExtension: "jsonl")
        
        let metadata = Metadata(username: username, userInputDescription: popUpView.userInputDescription, sceneType: sceneType, gpsLocation: gpsLocation, streams: [rgbStreamInfo, depthStreamInfo, confidenceMapStreamInfo, cameraInfoStreamInfo], numberOfFiles: 5)

        let metadataPath = (dirUrl.path as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension("json")!)
        
        metadata.display()
        metadata.writeToFile(filepath: metadataPath)
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
extension ARCameraViewController: ARSessionDelegate {
    
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
