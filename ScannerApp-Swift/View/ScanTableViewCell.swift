//
//  ScanListTableViewCell.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-23.
//  Copyright © 2019 jx16. All rights reserved.
//

import AVFoundation
import UIKit

protocol ScanTableViewCellDelegate {
    func deleteSuccess(fileId: String)
    func deleteFailed(fileId: String)
    func didCompletedUploadWithError(fileId: String)
    func didCompletedUploadWithoutError(fileId: String)
}

class ScanTableViewCell: UITableViewCell {

    private var url: URL!
    var scanTableViewCellDelegate: ScanTableViewCellDelegate!
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCellWithURL(url: URL) {
        self.url = url
        
        self.titleLabel.text = url.lastPathComponent
        
        if url.hasDirectoryPath {
            var fileURLs: [URL] = []
            do {
                fileURLs = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            } catch {
                print("Error while enumerating files \(url.path): \(error.localizedDescription)")
            }
            
            var infoText = ""
            for fileUrl in fileURLs {
                let extention = fileUrl.pathExtension
                infoText = infoText + extention + " "
                
                if extention == "mp4" {
                    generateThumbnail(videoUrl: fileUrl)
                }
            }
            
            self.infoLabel.text = infoText
            
        } else {
            self.infoLabel.text = url.pathExtension
        }
        
        self.infoLabel.textColor = .darkGray
        
        self.uploadProgressView.isHidden = true
    }
    
    private func generateThumbnail(videoUrl: URL) {
        let asset = AVAsset(url: videoUrl)
        let generator = AVAssetImageGenerator.init(asset: asset)
        let cgImage = try! generator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
        self.thumbnail.image = UIImage(cgImage: cgImage)
//        firstFrame.image = UIImage(cgImage: cgImage)
    }
    
    // TODO: behavior related stuff probably should be in a controller class
    @IBAction func uploadButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.uploadButton.isEnabled = false
            self.deleteButton.isEnabled = false
            self.uploadProgressView.isHidden = false
        }
        
        let requestHandler = HttpRequestHandler(delegate: self)
        requestHandler.upload(toUpload: url)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        do {
            try FileManager.default.removeItem(at: url)
            scanTableViewCellDelegate.deleteSuccess(fileId: url.lastPathComponent)
        } catch {
            print("failed to remove \(url.absoluteString)")
            scanTableViewCellDelegate.deleteFailed(fileId: url.lastPathComponent)
        }
    }
}

extension ScanTableViewCell: HttpRequestHandlerDelegate {
    
    func didReceiveUploadProgressUpdate(progress: Float) {
//        print(progress)
        DispatchQueue.main.async {
            self.uploadProgressView.progress = progress
        }
    }
    
    func didCompletedUploadWithError() {

        DispatchQueue.main.async {
            self.uploadButton.isEnabled = true
            self.deleteButton.isEnabled = true
            self.uploadProgressView.isHidden = true
            
            self.scanTableViewCellDelegate.didCompletedUploadWithError(fileId: self.url.lastPathComponent)
        }
    }
    
    func didCompletedUploadWithoutError() {
        DispatchQueue.main.async {
            self.uploadButton.isEnabled = true
            self.deleteButton.isEnabled = true
            self.uploadProgressView.isHidden = true
            
            self.scanTableViewCellDelegate.didCompletedUploadWithoutError(fileId: self.url.lastPathComponent)
        }
    }
}
