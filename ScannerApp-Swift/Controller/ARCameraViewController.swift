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

class ARCameraViewController: UIViewController {
    
//    let session = ARSession()
    
    let depthRecorder = DepthRecorder()
    let movieRecorder = MovieRecorder(videoSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoHeightKey: NSNumber(value: 1440), AVVideoWidthKey: NSNumber(value: 1920)])
    let cameraInfoRecorder = CameraInfoRecorder()
    
    var count: Int32 = 0
    var dirUrl: URL!
    var isRecording: Bool = false
    
    var cameraIntrinsic: simd_float3x3?
    
    @IBOutlet weak var arView: ARView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        dirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print(dirUrl.absoluteString)
        
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
            
        } else {
            count = 0
            
            cameraIntrinsic = arView.session.currentFrame?.camera.intrinsics
            
            print("pre1 count: \(count)")
            
            depthRecorder.prepareForDepthRecording(dirPath: dirUrl.path, filename: "testDepth")
            movieRecorder.prepareForRecording(dirPath: dirUrl.path, filenameWithoutExt: "testVideo")
            cameraInfoRecorder.prepareForDepthRecording(dirPath: dirUrl.path, filename: "testCamInfo")
            
            isRecording = true
            DispatchQueue.main.async {
                self.recordButton.setTitle("Recording...", for: .normal)
                self.recordButton.backgroundColor = .systemRed
            }
            
            print("pre2 count: \(count)")
            
        }
    }
    
    @IBAction func uploadButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.uploadButton.isEnabled = false
            self.deleteButton.isEnabled = false
        }
        
        let requestHandler = HttpRequestHandler(delegate: self)
        requestHandler.upload(toUpload: dirUrl)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        
        print("Removing files ...")
        
        do {
            let fileUrls = try FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileUrl in fileUrls {
                try FileManager.default.removeItem(at: fileUrl)
                
                print("Removed \(fileUrl.lastPathComponent).")
                
            }
        } catch {
            print(error)
            
        }
        
    }
    
    private func saveCameraIntrinsic() {
        
        if cameraIntrinsic != nil {
            let filePath = (dirUrl.path as NSString).appendingPathComponent(("testCameraIntrinsic" as NSString).appendingPathExtension("txt")!)
            let cameraIntrinsicArray = [cameraIntrinsic!.columns.0.x, cameraIntrinsic!.columns.0.y, cameraIntrinsic!.columns.0.z,
                                        cameraIntrinsic!.columns.1.x, cameraIntrinsic!.columns.1.y, cameraIntrinsic!.columns.1.z,
                                        cameraIntrinsic!.columns.2.x, cameraIntrinsic!.columns.2.y, cameraIntrinsic!.columns.2.z]
            FileManager.default.createFile(atPath: filePath, contents: "\(cameraIntrinsicArray)".data(using: .utf8), attributes: nil)
        } else {
            print("Camera intrinsic matrix not found.")
        }
        
    }
    
}

extension ViewController: ARSessionDelegate {
    
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
//        depthRecorder.displayBufferInfo(buffer: depthMap)
        depthRecorder.update(buffer: depthMap)

        print("**** @Controller: color \(count) ****")
//        depthRecorder.displayBufferInfo(buffer: colorImage)
        movieRecorder.update(buffer: colorImage, timestamp: timestamp)
        print()
    
        
        
        
        let currentCameraInfo = CameraInfo(timestamp: frame.timestamp,
                                           transform: frame.camera.transform,
                                           eulerAngles: frame.camera.eulerAngles,
                                           exposureDuration: frame.camera.exposureDuration)
        cameraInfoRecorder.update(cameraInfo: currentCameraInfo)
        
        
        
        
        
        // the smoothedSceneDepth thing does not work with the below code
//        guard let depthData = frame.smoothedSceneDepth else {
//            print("Failed to acquire depth data.")
//            return
//        }
//
//        let depthMap: CVPixelBuffer = depthData.depthMap
//        depthRecorder.displayBufferInfo(buffer: depthMap)
        
        
//        print("Saving color-\(count)...")
//        savePixelBufferAsPng(cvPixelBuffer: colorImage, url: dirUrl.appendingPathComponent("color-\(count).png"))
//
//        print("Saving depth-\(count)...")
//        savePixelBufferAsPng(cvPixelBuffer: depthMap, url: dirUrl.appendingPathComponent("depth-\(count).png"))
        
        count += 1
    }
    
    private func savePixelBufferAsPng(cvPixelBuffer: CVPixelBuffer, url: URL) {
        let ciImage = CIImage.init(cvImageBuffer: cvPixelBuffer)
        let data = UIImage.init(ciImage: ciImage).pngData()
        
        do {
            try data?.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension ViewController: HttpRequestHandlerDelegate {
    
    func didReceiveUploadProgressUpdate(progress: Float) {
        print("Uploading... \(progress)")
    }
    
    func didCompletedUploadWithError() {

        DispatchQueue.main.async {
            self.uploadButton.isEnabled = true
            self.deleteButton.isEnabled = true
            
            print("Upload failed.")
        }
    }
    
    func didCompletedUploadWithoutError() {
        DispatchQueue.main.async {
            self.uploadButton.isEnabled = true
            self.deleteButton.isEnabled = true
            
            print("Upload Succeeded.")
        }
    }
}
