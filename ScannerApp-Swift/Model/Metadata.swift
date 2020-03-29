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
    private var num_frames: Int
    
    internal init(id: String, type: String, encoding: String, num_frames: Int) {
        self.id = id
        self.type = type
        self.encoding = encoding
        self.num_frames = num_frames
    }
}

class CameraStreamInfo: StreamInfo {
    private var resolution: [Int]
    private var focal_length: [Float]
    private var principal_point: [Float]
    private var extrinsics_matrix: [Float]?
    
    internal init(id: String, type: String, encoding: String, num_frames: Int, resolution: [Int], focal_length: [Float], principal_point: [Float], extrinsics_matrix: [Float]?) {
        self.resolution = resolution
        self.focal_length = focal_length
        self.principal_point = principal_point
        self.extrinsics_matrix = extrinsics_matrix
        super.init(id: id, type: type, encoding: encoding, num_frames: num_frames)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(focal_length, forKey: .focal_length)
        try container.encode(principal_point, forKey: .principal_point)
        try container.encode(extrinsics_matrix, forKey: .extrinsics_matrix)
    }
    
    enum CodingKeys: String, CodingKey {
        case resolution
        case focal_length
        case principal_point
        case extrinsics_matrix
    }
}

class ImuStreamInfo: StreamInfo {
    private var frequency: Int
    
    internal init(id: String, type: String, encoding: String, num_frames: Int, frequency: Int) {
        self.frequency = frequency
        super.init(id: id, type: type, encoding: encoding, num_frames: num_frames)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frequency, forKey: .frequency)
    }
    
    enum CodingKeys: String, CodingKey {
        case frequency
    }
}

class Metadata: Encodable {
    
    private var device: DeviceInfo
    private var user: UserInfo
    private var scene: SceneInfo
    private var streams: [StreamInfo]
    
    init(username: String, userInputDescription: String, sceneType: String, gpsLocation: [Double],
         streams: [StreamInfo]) {
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString
        let modelName = Helper.getDeviceModelCode()
        let deviceName = UIDevice.current.name
        
        device = .init(id: deviceId!, type: modelName, name: deviceName)
        user = .init(name: username)
        scene = .init(description: userInputDescription, type: sceneType, gps_location: gpsLocation)
        self.streams = streams
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
