//
//  CameraViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-20.
//  Copyright © 2020 jx16. All rights reserved.
//

import ARKit
import RealityKit
import UIKit

enum RecordingMode {
    case singleCamera
    case dualCamera
    case arCamera
    case none
}

class CameraViewController: UIViewController, CameraViewControllerPopUpViewDelegate {
    
    private var mode: RecordingMode = .none
    
    private var recordingManager: RecordingManager! = nil
    private var popUpView: PopUpView = PopUpView()

    init(mode: RecordingMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        
        initRecordingManagerAndSetupPreview()
        setupPopUpView()
        setupRecordButton()
        
        // dismiss keyboard when tap elsewhere
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // The screen shouldn't dim during AR experiences.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func initRecordingManagerAndSetupPreview() {
        
        switch mode {
        case .singleCamera:
            recordingManager = SingleCameraRecordingManager()
        
        case .dualCamera:
            print("Dual camera mode not supported yet.")
            // TODO: do something
        
        case .arCamera:
            if #available(iOS 14.0, *) {
                
                recordingManager = ARCameraRecordingManager()
                let session = recordingManager.getSession() as! ARSession
                let arView = ARView()
                arView.session = session
                
                view.addSubview(arView)
                arView.translatesAutoresizingMaskIntoConstraints = false
                arView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
                arView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
                arView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
                arView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
                
            } else {
                print("AR camera only available for iOS 14.0 or newer.")
                // TODO: do something
            }
        
        default:
            print("Error, recording mode is not specified.")
            // TODO: do something
        }
        
    }

    private func setupPopUpView() {
        
        popUpView.delegate = self
        
        view.addSubview(popUpView)
        
        popUpView.translatesAutoresizingMaskIntoConstraints = false
        popUpView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popUpView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        DispatchQueue.main.async {
            self.popUpView.isHidden = true
        }
        
    }
    
    private func setupRecordButton() {
        
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8).isActive = true
        
    }
    
    private let recordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Record", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.setTitleColor(.gray, for: .disabled)
        btn.backgroundColor = .systemBlue
        btn.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    @objc func recordButtonTapped() {
        
        print("Record button tapped")
        
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
        
    }
    
}
