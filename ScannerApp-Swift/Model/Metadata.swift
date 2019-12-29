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
    var colorFocalX: Double // TODO: check if these should be float or double
    var colorFocalY: Double
    var colorCenterX: Double
    var colorCenterY: Double
    var depthFocalX: Double?
    var depthFocalY: Double?
    var depthCenterX: Double?
    var depthCenterY: Double?
    var colorToDepthExtrinsics: [Double]
    var deviceId: String
    var deviceName: String
    var sceneLabel: String // Should this be Int?
    var sceneType: String
    var username: String
    
    var numDepthFrames: Int = 0
    var numColorFrames: Int = 0
    var numIMUmeasurements: Int = 0

//    init(colorWidth: Int, colorHeight: Int,
//         deviceId: String, deviceName: String, sceneLabel: String, sceneType: String) {
//        // TODO:
//    }
    
    init(colorWidth: Int, colorHeight: Int, depthWidth: Int, depthHeight: Int,
         deviceId: String, deviceName: String, sceneLabel: String, sceneType: String, username: String) {
        self.colorWidth = colorWidth
        self.colorHeight = colorHeight
        self.depthWidth = depthWidth
        self.depthHeight = depthHeight
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.sceneLabel = sceneLabel
        self.sceneType = sceneType
        self.username = username
        
        self.colorToDepthExtrinsics = []
        
        // TODO:
        self.colorFocalX = 0
        self.colorFocalY = 0
        self.colorCenterX = 0
        self.colorCenterY = 0
        self.depthFocalX = 0
        self.depthFocalY = 0
        self.depthCenterX = 0
        self.depthCenterY = 0
        
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
    }
    
    func display() {
        // TODO:
        // need to check if depth related info is available
        // info is not complete
        
        print("colorWidth = \(self.colorWidth)")
        print("colorHeight = \(self.colorHeight)")
//        print("depthWidth = \(self.depthWidth)")
//        print("depthHeight = \(self.depthHeight)")
        print("fx_color = \(self.colorFocalX)")
        print("fy_color = \(self.colorFocalY)")
        print("mx_color = \(self.colorCenterX)")
        print("my_color = \(self.colorCenterY)")
//        print("fx_depth = \(self.depthFocalX)")
//        print("fy_depth = \(self.depthFocalY)")
//        print("mx_depth = \(self.depthCenterX)")
//        print("my_depth = \(self.depthCenterY)")
        print("deviceId = \(self.deviceId)")
        print("deviceName = \(self.deviceName)")
        print("sceneLabel = \(self.sceneLabel)")
        print("sceneType = \(self.sceneType)")
        print("username = \(self.username)")
//        print("appVersionId = \(APP_VERSION_ID.c_str())")
    }
    
    func writeToFile(filepath: String) {
        let strToWrite: String =
        "colorWidth = \(self.colorWidth)\n" +
        "colorHeight = \(self.colorHeight)\n" +
//        "depthWidth = \(self.depthWidth)\n" +
//        "depthHeight = \(self.depthHeight)\n" +
        "fx_color = \(self.colorFocalX)\n" +
        "fy_color = \(self.colorFocalY)\n" +
        "mx_color = \(self.colorCenterX)\n" +
        "my_color = \(self.colorCenterY)\n" +
//        "fx_depth = \(self.depthFocalX)\n" +
//        "fy_depth = \(self.depthFocalY)\n" +
//        "mx_depth = \(self.depthCenterX)\n" +
//        "my_depth = \(self.depthCenterY)\n" +
        "deviceId = \(self.deviceId)\n" +
        "deviceName = \(self.deviceName)\n" +
        "sceneLabel = \(self.sceneLabel)\n" +
        "sceneType = \(self.sceneType)\n" +
        "username = \(self.username)\n"
        
//        "appVersionId = \(APP_VERSION_ID.c_str())"
        
        try! strToWrite.write(toFile: filepath, atomically: true, encoding: .utf8)
    }
}

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
