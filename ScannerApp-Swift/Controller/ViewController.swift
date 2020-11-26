//
//  ViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit
import ARKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var dualCamButton: UIButton!
    @IBOutlet weak var lidarDepthButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dualCamButton.isEnabled = false
        if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported {
            dualCamButton.isEnabled = true
        } else {
            dualCamButton.isEnabled = false
        }
        
        if #available(iOS 14.0, *), ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            lidarDepthButton.isEnabled = true
        } else {
            lidarDepthButton.isEnabled = false
        }
    }
    
    
    
    
    @IBAction func testButtonTapped(_ sender: Any) {
        
        let vc = CameraViewController(mode: .arCamera)
        vc.modalPresentationStyle = .fullScreen
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
