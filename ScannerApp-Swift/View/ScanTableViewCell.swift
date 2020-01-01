//
//  ScanListTableViewCell.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-23.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit

protocol ScanTableViewCellDelegate {
    func didTappedDelete()
}

class ScanTableViewCell: UITableViewCell {

    private var url: URL!
    var scanTableViewCellDelegate: ScanTableViewCellDelegate!
    
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
        
        self.infoLabel.text = url.pathExtension
        self.infoLabel.textColor = .darkGray
        
        self.uploadProgressView.isHidden = true
    }
    
    // TODO: behavior related stuff probably should be in a controller class
    @IBAction func uploadButtonTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.uploadButton.isEnabled = false
            self.deleteButton.isEnabled = false
            self.uploadProgressView.isHidden = false
        }
        
        let requestHandler = HttpRequestHandler()
        requestHandler.httpRequestHandlerDelegate = self
        requestHandler.upload(toUpload: url)
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        // TODO
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Remove file failed")
        }
        scanTableViewCellDelegate.didTappedDelete()
    }
}

extension ScanTableViewCell: HttpRequestHandlerDelegate {
    
    func didReceiveUploadProgressUpdate(progress: Float) {
//        print(progress)
        DispatchQueue.main.async {
            self.uploadProgressView.progress = progress
        }
    }
    
    func didCompleteUpload(data: Data?, response: URLResponse?, error: Error?) {

        DispatchQueue.main.async {
            self.uploadButton.isEnabled = true
            self.deleteButton.isEnabled = true
            self.uploadProgressView.isHidden = true
        }
        
        print("test code")
        
        if let error = error {
            print ("error: \(error)")
            return
        }
        guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode) else {
                print ("server error")
                return
        }
        if let mimeType = response.mimeType,
            mimeType == "application/json",
            let data = data,
            let dataString = String(data: data, encoding: .utf8) {
            print ("got data: \(dataString)")
        }
    }
}
