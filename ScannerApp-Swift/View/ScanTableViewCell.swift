//
//  ScanListTableViewCell.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-23.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit

class ScanTableViewCell: UITableViewCell {

    private var url: URL!
    
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
        
        self.infoLabel.text = "Some more info to show"
        self.infoLabel.textColor = .darkGray
    }
    
    @IBAction func uploadButtonTapped(_ sender: Any) {
        // TODO
    }
    
    @IBAction func deleteButtonTapped(_ sender: Any) {
        // TODO
    }
}
