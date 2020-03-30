//
//  Helper.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-10.
//  Copyright © 2020 jx16. All rights reserved.
//

import AVFoundation
import CommonCrypto
import Foundation
import UIKit

struct Helper {
    
    // https://forums.developer.apple.com/thread/101874
    static func bootTime() -> Double? {
        var tv = timeval()
        var tvSize = MemoryLayout<timeval>.size
        let err = sysctlbyname("kern.boottime", &tv, &tvSize, nil, 0);
        guard err == 0, tvSize == MemoryLayout<timeval>.size else {
            return nil
        }
//        return Date(timeIntervalSince1970: Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000.0)
        return Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000.0
    }

    // https://stackoverflow.com/questions/42935148/swift-calculate-md5-checksum-for-large-files
    static func calculateChecksum(url: URL) -> String? {
        
        let bufferSize = Constants.Server.chuckSize

        do {
            // Open file for reading:
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // Create and initialize MD5 context:
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)

            // Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_MD5_Update(&context, $0.baseAddress, numericCast(data.count))
                    }
                    return true // Continue
                } else {
                    return false // End of file
                }
            }) { }

            // Compute the MD5 digest:
            var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = CC_MD5_Final(&digest, &context)

//            return Data(digest)
            let hexDigest = digest.map { String(format: "%02hhx", $0) }.joined()
            return hexDigest

        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
    
    static func getDeviceModelCode() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
// https://stackoverflow.com/questions/29506411/ios-determine-number-of-frames-in-video
    static func getNumberOfFrames(videoUrl url: URL) -> Int {
        
        let asset = AVURLAsset(url: url, options: nil)
        do {
            let reader = try AVAssetReader(asset: asset)
            //AVAssetReader(asset: asset, error: nil)
            
            let videoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
            
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
            reader.add(readerOutput)
            reader.startReading()
            
            var nFrames = 0
            
            while true {
                let sampleBuffer = readerOutput.copyNextSampleBuffer()
                if sampleBuffer == nil {
                    break
                }
                
                nFrames += 1
            }
            
            return nFrames
            
        } catch {
            print("Error: \(error)")
        }
        
        return 0
    }
    
    // https://medium.com/@rushikeshT/displaying-simple-toast-in-ios-swift-57014cbb9ffa
    static func showToast(controller: UIViewController, message : String, seconds: Double) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = .black
        alert.view.alpha = 0.5
        alert.view.layer.cornerRadius = 15
        controller.present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
            alert.dismiss(animated: true)
        }
    }
}
