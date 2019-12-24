//
//  LibraryViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-23.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit

class LibraryViewController: UITableViewController {
    
    private let fileManager = FileManager.default
    private let cellIdentifier = "scanTableViewCell"
    
    private var fileURLs: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // test code
//        print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true))
        
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            // test code
//            print(fileURLs)
            
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        
        let scanTableViewCell = UINib(nibName: "ScanTableViewCell", bundle: nil)
        tableView.register(scanTableViewCell, forCellReuseIdentifier: cellIdentifier)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileURLs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ScanTableViewCell
//        cell.textLabel?.text = fileURLs[indexPath.item].lastPathComponent
//        cell.textLabel?.text = fileURLs[indexPath.item].absoluteString
        
        cell.setupCellWithURL(url: fileURLs[indexPath.item])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
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
