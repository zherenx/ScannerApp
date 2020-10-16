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

@available(iOS 14.0, *)
class ARCameraViewController: UIViewController {
    
//    let session = ARSession()
    
    let depthRecorder = DepthRecorder()
    let movieRecorder = MovieRecorder(videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: 1440), AVVideoWidthKey: NSNumber(value: 1920)])
    let cameraInfoRecorder = CameraInfoRecorder()
    
    var count: Int32 = 0
    var dirUrl: URL!
    var recordingId: String!
    var isRecording: Bool = false
    
    var cameraIntrinsic: simd_float3x3?
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var recordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        arView.session.delegate = self
//        session.delegate = self

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
//        session.run(configuration)
        arView.session.run(configuration)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        count = 0
        
        cameraIntrinsic = arView.session.currentFrame?.camera.intrinsics
        
        print("pre1 count: \(count)")
        
        recordingId = Helper.getRecordingId()
        dirUrl = URL(fileURLWithPath: Helper.getRecordingDataDirectoryPath(recordingId: recordingId))
        
        depthRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
        movieRecorder.prepareForRecording(dirPath: dirUrl.path, filenameWithoutExt: recordingId)
        cameraInfoRecorder.prepareForRecording(dirPath: dirUrl.path, filename: recordingId)
        
        isRecording = true
        DispatchQueue.main.async {
            self.recordButton.setTitle("Recording...", for: .normal)
            self.recordButton.backgroundColor = .systemRed
        }
        
        print("pre2 count: \(count)")
    }
    
    private func stopRecording() {
        print("post count: \(count)")
        
        isRecording = false
        
        depthRecorder.finishRecording()
        movieRecorder.finishRecording()
        cameraInfoRecorder.finishRecording()
        
        saveCameraIntrinsic()
        
        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .none
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

        print("**** @Controller: depth \(count) ****")
        depthRecorder.update(buffer: depthMap)

        print("**** @Controller: color \(count) ****")
        movieRecorder.update(buffer: colorImage, timestamp: timestamp)
        print()
    
        let currentCameraInfo = CameraInfo(timestamp: frame.timestamp,
                                           transform: frame.camera.transform,
                                           eulerAngles: frame.camera.eulerAngles,
                                           exposureDuration: frame.camera.exposureDuration)
        cameraInfoRecorder.update(cameraInfo: currentCameraInfo)
        
        count += 1
    }
}
