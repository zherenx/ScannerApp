//
//  RecordingManager.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-11-17.
//  Copyright © 2020 jx16. All rights reserved.
//

protocol RecordingManager {
    func startRecording()
    func finishRecordingAndReturnStreamInfo() -> [StreamInfo]
    func getSession() -> NSObject
}
