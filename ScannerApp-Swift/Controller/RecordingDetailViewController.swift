//
//  RecordingDetailViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-04-24.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit

class RecordingDetailViewController: UIViewController {
    
    var recordingUrl: URL?

    @IBOutlet weak var thumbnailImageView: UIImageView!
    
    @IBOutlet private weak var recordingIdLabel: UILabel!
    
    @IBOutlet weak var recordingDetailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateView()
    }

    private func populateView() {
        
        if let recordingUrl = recordingUrl {
            
            recordingIdLabel.text = "Recording ID: \(recordingUrl.lastPathComponent)"
            
            if recordingUrl.hasDirectoryPath {
                var fileURLs: [URL] = []
                do {
                    fileURLs = try FileManager.default.contentsOfDirectory(at: recordingUrl, includingPropertiesForKeys: nil)
                } catch {
                    print("Error while enumerating files \(recordingUrl.path): \(error.localizedDescription)")
                }
                
                for fileUrl in fileURLs {
                    let extention = fileUrl.pathExtension
                    
                    // TODO: if statement might work better here
                    switch extention {
                    case "mp4":
                        let thumbnail = VideoHelper.generateThumbnail(videoUrl: fileUrl)
                        thumbnailImageView.image = UIImage(cgImage: thumbnail)
                    case "json":
                        recordingDetailLabel.text = "recording detail ..."
                    default:
                        break
                    }
                }
            } else {
                // if url is a file
                
                // TODO: maybe this else block is not necessary
                recordingDetailLabel.text = ""
            }
        } else {
            print("Internal error!\nRecording url is not valid.")
        }
        
    }
}