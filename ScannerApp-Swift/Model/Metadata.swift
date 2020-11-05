//
//  Metadata.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-27.
//  Copyright © 2019 jx16. All rights reserved.
//

import Foundation
import UIKit

class DeviceInfo: Codable {
    private var id: String
    private var type: String
    private var name: String
    
    internal init(id: String, type: String, name: String) {
        self.id = id
        self.type = type
        self.name = name
    }
}

class UserInfo: Codable {
    private var name: String
    
    internal init(name: String) {
        self.name = name
    }
}

class SceneInfo: Codable {
    private var description: String
    private var type: String
    private var gps_location: [Double]
    
    internal init(description: String, type: String, gps_location: [Double]) {
        self.description = description
        self.type = type
        self.gps_location = gps_location
    }
}

class StreamInfo: Encodable {
    private var id: String
    private var type: String
    private var encoding: String
    private var frequency: Int
    private var num_frames: Int
    private var file_extension: String
    
    internal init(id: String, type: String, encoding: String, frequency: Int, num_frames: Int, file_extension: String) {
        self.id = id
        self.type = type
        self.encoding = encoding
        self.frequency = frequency
        self.num_frames = num_frames
        self.file_extension = file_extension
    }
}

class CameraStreamInfo: StreamInfo {
    private var resolution: [Int]
    private var intrinsics_matrix: [Float]?
    private var extrinsics_matrix: [Float]?
    
    internal init(id: String, type: String, encoding: String, frequency: Int, num_frames: Int, file_extension: String, resolution: [Int], intrinsics_matrix: [Float]?, extrinsics_matrix: [Float]?) {
        self.resolution = resolution
        self.intrinsics_matrix = intrinsics_matrix
        self.extrinsics_matrix = extrinsics_matrix
        super.init(id: id, type: type, encoding: encoding, frequency: frequency, num_frames: num_frames, file_extension: file_extension)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(intrinsics_matrix, forKey: .intrinsics_matrix)
        try container.encode(extrinsics_matrix, forKey: .extrinsics_matrix)
    }
    
    enum CodingKeys: String, CodingKey {
        case resolution
        case focal_length
        case principal_point
        case intrinsics_matrix
        case extrinsics_matrix
    }
}

class ImuStreamInfo: StreamInfo {
    // this subclass was used to handle 'frequency' which has been moved to StreamInfo,
    // so it is currently the same as its superclass
    
    // TODO: Add 'precision' info of imu sensor
    
    internal init(id: String, type: String, encoding: String, num_frames: Int, frequency: Int, file_extension: String) {
        super.init(id: id, type: type, encoding: encoding, frequency: frequency, num_frames: num_frames, file_extension: file_extension)
    }
    
//    override func encode(to encoder: Encoder) throws {
//        try super.encode(to: encoder)
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(frequency, forKey: .frequency)
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case frequency
//    }
}

class Metadata: Encodable {
    
    private var device: DeviceInfo
    private var user: UserInfo
    private var scene: SceneInfo
    private var streams: [StreamInfo]
    private var number_of_files: Int
    
    init(username: String, userInputDescription: String, sceneType: String, gpsLocation: [Double],
         streams: [StreamInfo], number_of_files: Int) {
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString
        let modelName = Helper.getDeviceModelCode()
        let deviceName = UIDevice.current.name
        
        device = .init(id: deviceId!, type: modelName, name: deviceName)
        user = .init(name: username)
        scene = .init(description: userInputDescription, type: sceneType, gps_location: gpsLocation)
        
        self.streams = streams
        self.number_of_files = number_of_files
    }
    
    func display() {
        print(self.getJsonEncoding())
    }
    
    func writeToFile(filepath: String) {
        try! self.getJsonEncoding().write(toFile: filepath, atomically: true, encoding: .utf8)
    }
    
    func getJsonEncoding() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}
