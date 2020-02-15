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

class Metadata: CustomData, Encodable {
    
    private var device: DeviceInfo
    private var user: UserInfo
    private var scene: SceneInfo
    private var streams: [StreamInfo]
    
//    private var deviceId: String
//    private var modelName: String
//    private var sceneLabel: String // Should this be Int?
//    private var sceneType: String
//
//    private var sensorTypes: [String]
//    private var numMeasurements: [String: Int] // does this make more sense??
//
//    private var username: String // Do we still need this?
//    private var userInputDescription: String
//
//    // Camera intrinsics
//    private var colorWidth: Int
//    private var colorHeight: Int
//    private var colorFocalX: Double // TODO: check if these should be float or double
//    private var colorFocalY: Double
//    private var colorCenterX: Double
//    private var colorCenterY: Double

    
//    init(deviceId: String, modelName: String, sceneLabel: String, sceneType: String,
////         numColorFrames: Int, numImuMeasurements: Int,
//         sensorTypes: [String], numMeasurements: [String: Int],
//         username: String, userInputDescription: String,
//         colorWidth: Int, colorHeight: Int) {
//
//        self.deviceId = deviceId
//        self.modelName = modelName
//        self.sceneLabel = sceneLabel
//        self.sceneType = sceneType
//
////        self.numColorFrames = numColorFrames
////        self.numImuMeasurements = numImuMeasurements
//        self.numMeasurements = numMeasurements
//
//        self.username = username
//        self.userInputDescription = userInputDescription
//        self.sensorTypes = sensorTypes
//
//        self.colorWidth = colorWidth
//        self.colorHeight = colorHeight
//
//        // TODO: calculate these var, might need to pass in camera matrix
//        self.colorFocalX = 0
//        self.colorFocalY = 0
//        self.colorCenterX = 0
//        self.colorCenterY = 0
//    }
    
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
        
//        GLKVector4 getIntrinsicsFromGlProj(const GLKMatrix4& matrix, unsigned int width, unsigned int height, bool useHalf)
//        {
//            float fov = 2.0f * atan(1.0f / matrix.m00);
//            float aspect = (float)width / height;
//            float t = tan(0.5f * fov);
//            float fx = 0.5f * width / t;
//            float fy = 0.5f * height / t * aspect;
//
//            float mx = (float)(width - 1.0f) / 2.0f;
//            float my = (float)(height - 1.0f) / 2.0f;
//
//            if (useHalf) {
//                fx *= 0.5f; fy *= 0.5f;
//                mx *= 0.5f; my *= 0.5f;
//            }
//            GLKVector4 ret = GLKVector4Make(fx, fy, mx, my);
//            return ret;
//        }






//void writeIntrinsics(const Options& options)
//{
//    unsigned int colorWidth = options.useHalfResColor ? options.colorWidth / 2 : options.colorWidth;
//    unsigned int colorHeight = options.useHalfResColor ? options.colorHeight / 2 : options.colorHeight;
//    fprintf(g_metaFile, "colorWidth = %d\r\n", colorWidth);
//    fprintf(g_metaFile, "colorHeight = %d\r\n", colorHeight);
//    fprintf(g_metaFile, "depthWidth = %d\r\n", options.depthWidth);
//    fprintf(g_metaFile, "depthHeight = %d\r\n", options.depthHeight);
//
//    fprintf(g_metaFile, "fx_color = %f\r\n", options.colorFocalX);
//    fprintf(g_metaFile, "fy_color = %f\r\n", options.colorFocalY);
//    fprintf(g_metaFile, "mx_color = %f\r\n", options.colorCenterX);
//    fprintf(g_metaFile, "my_color = %f\r\n", options.colorCenterY);
//
//    fprintf(g_metaFile, "fx_depth = %f\r\n", options.depthFocalX);
//    fprintf(g_metaFile, "fy_depth = %f\r\n", options.depthFocalY);
//    fprintf(g_metaFile, "mx_depth = %f\r\n", options.depthCenterX);
//    fprintf(g_metaFile, "my_depth = %f\r\n", options.depthCenterY);
//
//    std::string colorToDepthExt = "";
//    for(int i = 0; i < 16; i++) {
//        colorToDepthExt += std::to_string(options.colorToDepthExtrinsics[i]) + " ";
//    }
//
//    fprintf(g_metaFile, "colorToDepthExtrinsics = %s\r\n", colorToDepthExt.c_str());
//
//    fprintf(g_metaFile, "deviceId = %s\r\n", options.deviceId.c_str());
//    fprintf(g_metaFile, "deviceName = %s\r\n", options.deviceName.c_str());
//    fprintf(g_metaFile, "sceneLabel = %s\r\n", options.sceneLabel.c_str());
//    fprintf(g_metaFile, "sceneType = %s\r\n", options.specifiedSceneType.c_str());
//    fprintf(g_metaFile, "userName = %s\r\n", options.userName.c_str());
//    fprintf(g_metaFile, "appVersionId = %s\r\n", APP_VERSION_ID.c_str());
//    fflush(g_metaFile);
//}

//struct Options //TODO get rid of mesh view/tracking params
//{
//    // Whether we should use depth aligned to the color viewpoint when Structure Sensor was calibrated.
//    // This setting may get overwritten to false if no color camera can be used.
//
//    bool useHardwareRegisteredDepth = false;
//
//    // Focus position for the color camera (between 0 and 1). Must remain fixed one depth streaming
//    // has started when using hardware registered depth.
//    const float lensPosition = 0.75f;
//
//    unsigned int colorEncodeBitrate = 5000;
//
//    //meta-data (res, intrinsics)
//    unsigned int colorWidth = 640;
//    unsigned int colorHeight = 480;
//    unsigned int depthWidth = 640;
//    unsigned int depthHeight = 480;
//    float colorFocalX = 578.0f; float colorFocalY = 578.0f; float colorCenterX = 320.0f; float colorCenterY = 240.0f; //default for VGA
//    float depthFocalX = 570.5f; float depthFocalY = 570.5f; float depthCenterX = 320.0f; float depthCenterY = 240.0f; //default for VGA
//    bool useHalfResColor = false;
//
//    float colorToDepthExtrinsics[16];
//
//    std::string sceneLabel = "";
//
//    std::string deviceId = "";
//    std::string deviceName = "";
//
//    std::string specifiedSceneType = "";
//
//    std::string userName = "";
//};
