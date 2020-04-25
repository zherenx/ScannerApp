//
//  RecordingDetailViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-04-24.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit

class RecordingDetailViewController: UIViewController {
    
    public var recordingUrl: URL?

    @IBOutlet private weak var recordingUrlLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        recordingUrlLabel.text = recordingUrl?.lastPathComponent
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
