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
    let rgbRecorder = RGBRecorder(videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: 1440), AVVideoWidthKey: NSNumber(value: 1920)])
    let cameraInfoRecorder = CameraInfoRecorder()
    
    var numFrames: Int = 0
    var dirUrl: URL!
    var recordingId: String!
    var isRecording: Bool = false
    
    let locationManager = CLLocationManager()
    var gpsLocation: [Double] = []
    
    var cameraIntrinsic: simd_float3x3?
    var colorFrameResolution: CGSize?
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        session.run(configuration)
//        arView.session.run(configuration)
        
        let videoFormat = configuration.videoFormat
        frequency = videoFormat.framesPerSecond
        colorFrameResolution = videoFormat.imageResolution
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        if isRecording {
            stopRecording()
        } else {
            DispatchQueue.main.async {
                self.popUpView.isHidden = false
            }
        }
    }
    
    func startRecording() {
        
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
        
        gpsLocation = getGpsLocation()
        
        numFrames = 0
        
        if let currentFrame = session.currentFrame {
            cameraIntrinsic = currentFrame.camera.intrinsics
            
                // TODO: maybe get depth format here?
        }
        
        print("pre1 count: \(numFrames)")
        
        recordingId = Helper.getRecordingId()
        dirUrl = URL(fileURLWithPath: Helper.getRecordingDataDirectoryPath(recordingId: recordingId))
        
        depthRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
        rgbRecorder.prepareForRecording(dirPath: dirUrl.path, filenameWithoutExt: recordingId)
        cameraInfoRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
        
        isRecording = true
        DispatchQueue.main.async {
            self.recordButton.setTitle("Recording...", for: .normal)
            self.recordButton.backgroundColor = .systemRed
        }
        
        print("pre2 count: \(numFrames)")
    }
    
    func dismissPopUpView() {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
    }
    
    func stopRecording() {
        print("post count: \(numFrames)")
        
        isRecording = false
        
        depthRecorder.finishRecording()
        rgbRecorder.finishRecording()
        cameraInfoRecorder.finishRecording()
        
        saveCameraIntrinsic()
        saveMetadata()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
        }
    }
    
    private func saveCameraIntrinsic() {
        
        if cameraIntrinsic != nil {
            let filePath = (dirUrl.path as NSString).appendingPathComponent((recordingId as NSString).appendingPathExtension("txt")!)
            let cameraIntrinsicArray = [cameraIntrinsic!.columns.0.x, cameraIntrinsic!.columns.0.y, cameraIntrinsic!.columns.0.z,
                                        cameraIntrinsic!.columns.1.x, cameraIntrinsic!.columns.1.y, cameraIntrinsic!.columns.1.z,
                                        cameraIntrinsic!.columns.2.x, cameraIntrinsic!.columns.2.y, cameraIntrinsic!.columns.2.z]
            FileManager.default.createFile(atPath: filePath, contents: "\(cameraIntrinsicArray)".data(using: .utf8), attributes: nil)
        } else {
            print("Camera intrinsic matrix not found.")
        }
        
    }
    
    private func saveMetadata() {
        
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

        let timestamp: CMTime = CMTime(seconds: frame.timestamp, preferredTimescale: 1_000_000_000)

        print("**** @Controller: depth \(numFrames) ****")
        depthRecorder.update(buffer: depthMap)

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
