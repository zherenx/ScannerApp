//
//  MotionDataProcessor.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-24.
//  Copyright © 2019 jx16. All rights reserved.
//

import CoreMotion
import Foundation

class MotionDataProcessor {
    static func processDeviceMotion(deviceMotion data: CMDeviceMotion) {
        print(data)
    }
    
    static func processDeviceMotionAndWriteToFile(deviceMotion data: CMDeviceMotion, filePath: String) {
        print(data)
    }
}
