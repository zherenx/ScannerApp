//
//  ViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var dualCamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dualCamButton.isEnabled = false
        if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported {
            dualCamButton.isEnabled = true
        }
    }
    
}
