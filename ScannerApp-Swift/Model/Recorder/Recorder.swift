//
//  Recorder.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-26.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation

protocol Recorder {
    associatedtype T
    
    func prepareForRecording(dirPath: String, filenameWithoutExt: String)
    func update(_: T, timestamp: CMTime?)
    func finishRecording()
}
