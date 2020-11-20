//
//  SingleCameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import UIKit

class SingleCameraViewController: UIViewController, CameraViewControllerPopUpViewDelegate {
    
    var recordingManager: RecordingManager! = nil
    
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var recordButton: UIButton!
    
    var popUpView: PopUpView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupPopUpView()
        
        recordingManager = SingleCameraRecordingManager()
        previewView.videoPreviewLayer.session = recordingManager.getSession() as? AVCaptureSession
        
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
    
    @IBAction private func recordButtonTapped(_ sender: Any) {
        
        if recordingManager.isRecording {
            
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
        
        let username = popUpView.firstName + " " + popUpView.lastName
        let sceneDescription = popUpView.userInputDescription
        let sceneType = popUpView.sceneTypes[popUpView.sceneTypeIndex]
        recordingManager.startRecording(username: username, sceneDescription: sceneDescription, sceneType: sceneType)
    }
    
    func dismissPopUpView() {
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
            self.recordButton.isEnabled = true
        }
    }
    
    func stopRecording() {
        recordingManager.stopRecording()

        DispatchQueue.main.async {
            self.recordButton.setTitle("Record", for: .normal)
            self.recordButton.backgroundColor = .systemBlue
        }
        
        
        // TODO: see what make sence
//        Helper.showToast(controller: self, message: "Finish recording\nfile prefix: \(recordingId)", seconds: 1)
        
    }

}
