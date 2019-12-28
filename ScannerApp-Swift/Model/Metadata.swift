//
//  Metadata.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-27.
//  Copyright © 2019 jx16. All rights reserved.
//

import Foundation

/*
    Metadata.txt example
    colorWidth = 1296
    colorHeight = 968
    depthWidth = 640
    depthHeight = 480
    fx_color = 1170.187988
    fy_color = 1170.187988
    mx_color = 647.750000
    my_color = 483.750000
    fx_depth = 571.623718
    fy_depth = 571.623718
    mx_depth = 319.500000
    my_depth = 239.500000
    colorToDepthExtrinsics = 0.999977 0.004401 0.005230 -0.037931 -0.004314 0.999852 -0.016630 -0.003321 -0.005303 0.016607 0.999848 -0.021860 -0.000000 0.000000 -0.000000 1.000000
    deviceId = AA408AE6-80BB-4E45-B6BA-5ECC8C17FB2F
    deviceName = iPad One
    sceneLabel = 0001
    sceneType = Bedroom / Hotel
    numDepthFrames = 1912
    numColorFrames = 1912
    numIMUmeasurements = 4185
 */

class Metadata: CustomData {
    
    var colorWidth: Int
    var colorHeight: Int
    var depthWidth: Int?
    var depthHeight: Int?
    var fx_color: Double // TODO: check if these should be float or double
    var fy_color: Double
    var mx_color: Double
    var my_color: Double
    var fx_depth: Double?
    var fy_depth: Double?
    var mx_depth: Double?
    var my_depth: Double?
    var colorToDepthExtrinsics: [Double]
    var deviceId: String
    var deviceName: String
    var sceneLabel: String // Should this be Int?
    var sceneType: String
    var numDepthFrames: Int = 0
    var numColorFrames: Int = 0
    var numIMUmeasurements: Int = 0

//    init(colorWidth: Int, colorHeight: Int,
//         deviceId: String, deviceName: String, sceneLabel: String, sceneType: String) {
//        self.colorWidth = colorWidth
//        self.colorHeight = colorHeight
//        self.deviceId = deviceId
//        self.deviceName = deviceName
//        self.sceneLabel = sceneLabel
//        self.sceneType = sceneType
//
//        self.colorToDepthExtrinsics = []
//
//        self.fx_color = 0
//        self.fy_color = 0
//        self.mx_color = 0
//        self.my_color = 0
//    }
    
    init(colorWidth: Int, colorHeight: Int, depthWidth: Int, depthHeight: Int,
         deviceId: String, deviceName: String, sceneLabel: String, sceneType: String) {
        self.colorWidth = colorWidth
        self.colorHeight = colorHeight
        self.depthWidth = depthWidth
        self.depthHeight = depthHeight
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.sceneLabel = sceneLabel
        self.sceneType = sceneType
        
        self.colorToDepthExtrinsics = []
        
        // TODO:
        self.fx_color = 0
        self.fy_color = 0
        self.mx_color = 0
        self.my_color = 0
        self.fx_depth = 0
        self.fy_depth = 0
        self.mx_depth = 0
        self.my_depth = 0
    }
    
    func display() {
        // TODO:
    }
    
    func writeToFile(filePointer: UnsafeMutablePointer<FILE>) {
        // TODO:
    }
}
