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
    }
    
    // TODO: behavior related stuff probably should be in a controller class
    @IBAction func uploadButtonTapped(_ sender: Any) {
        // TODO
        HttpRequestHandlerAPI.upload(toUpload: url)
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
