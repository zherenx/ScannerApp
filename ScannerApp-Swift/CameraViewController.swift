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
        
        previewView.session = session
//        self.previewView.videoPreviewLayer.session = self.session
        
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
    
    
    private let session = AVCaptureSession()
    
    @IBOutlet private weak var previewView: PreviewView!
    
    private func configurateSession() {
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // Input
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            session.canAddInput(videoDeviceInput)
            else {
                print("Error!!")
                return
                
        }
        session.addInput(videoDeviceInput)
        
        
        // Output
        let photoOutput = AVCapturePhotoOutput()
        guard session.canAddOutput(photoOutput) else {
            print("Error 2!!")
            return
        }
        session.sessionPreset = .photo
        session.addOutput(photoOutput)
        session.commitConfiguration()
    }
    

}
