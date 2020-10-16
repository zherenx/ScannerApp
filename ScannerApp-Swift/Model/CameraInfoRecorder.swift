//
//  CameraInfoRecorder.swift
//  LiDARDepth
//
//  Created by Zheren Xiao on 2020-10-08.
//  Copyright © 2020 jx16. All rights reserved.
//

import Foundation
import simd

//extension simd_float4x4: Codable {
//    public init(from decoder: Decoder) throws {
//        <#code#>
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        <#code#>
//    }
//}

class CameraInfo: Encodable {
    
    private var timestamp: Int64
//    private var transform: simd_float4x4
//    private var eulerAngles: simd_float3
    private var transform: [Float]
    private var eulerAngles: [Float]
    private var exposureDuration: Int64
    
    internal init(timestamp: TimeInterval, transform: simd_float4x4, eulerAngles: simd_float3, exposureDuration: TimeInterval) {
        self.timestamp = Int64(timestamp * 1_000_000_000.0)
//        self.transform = transform
//        self.eulerAngles = eulerAngles
        self.transform = [transform.columns.0.x, transform.columns.0.y, transform.columns.0.z, transform.columns.0.w,
                          transform.columns.1.x, transform.columns.1.y, transform.columns.1.z, transform.columns.1.w,
                          transform.columns.2.x, transform.columns.2.y, transform.columns.2.z, transform.columns.2.w,
                          transform.columns.3.x, transform.columns.3.y, transform.columns.3.z, transform.columns.3.w]
        self.eulerAngles = [eulerAngles.x, eulerAngles.y, eulerAngles.z]
        self.exposureDuration = Int64(exposureDuration * 1_000_000_000.0)
    }
    
    func getJsonEncoding() -> String {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
}

class CameraInfoRecorder {
    
    private let cameraInfoQueue = DispatchQueue(label: "camera info queue")
    
    private var fileHandle: FileHandle? = nil
    private var fileUrl: URL? = nil
    
    private var count: Int32 = 0
    
    func prepareForDepthRecording(dirPath: String, filename: String) {
        
        cameraInfoQueue.async {
            
            self.count = 0
            
            let filePath = (dirPath as NSString).appendingPathComponent((filename as NSString).appendingPathExtension("cam")!)
            self.fileUrl = URL(fileURLWithPath: filePath)
            FileManager.default.createFile(atPath: self.fileUrl!.path, contents: nil, attributes: nil)
            
            self.fileHandle = FileHandle(forUpdatingAtPath: self.fileUrl!.path)
            if self.fileHandle == nil {
                print("Unable to create file handle.")
                return
            }
        }
        
    }
    
    func update(cameraInfo: CameraInfo) {
        cameraInfoQueue.async {
            print("Saving camera info \(self.count) ...")
            
            print(cameraInfo.getJsonEncoding())
            self.fileHandle?.write((cameraInfo.getJsonEncoding() + "\n").data(using: .utf8)!)
            
            self.count += 1
        }
    }
    
    func finishRecording() {
        cameraInfoQueue.async {
            if self.fileHandle != nil {
                self.fileHandle!.closeFile()
                self.fileHandle = nil
            }
            
            print("\(self.count) frames of camera info saved.")
        }
    }
}
