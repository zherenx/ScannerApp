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
    func writeToFile(filepath: String)
}
