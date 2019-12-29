//
//  CustomData.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-28.
//  Copyright © 2019 jx16. All rights reserved.
//

import Foundation

protocol CustomData {
    func display()
    func writeToFile(filePointer: UnsafeMutablePointer<FILE>)
    func writeToFile(filepath: String, mode: String)
}

extension CustomData {
    func writeToFile(filepath: String, mode: String) {
        let filePointer = fopen(filepath, mode)
        writeToFile(filePointer: filePointer!)
        fclose(filePointer)
    }
}
