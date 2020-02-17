//
//  Helper.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-10.
//  Copyright © 2020 jx16. All rights reserved.
//

import CommonCrypto
import Foundation

class Helper {
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
    
//    NSString *calculateChecksum(NSString *fileName)
//    {
//        FILE *fp = fopen([fileName UTF8String], "rb");
//        uint8_t buf[READ_CHUNK_SIZE];
//
//        CC_MD5_CTX md5;
//        CC_MD5_Init(&md5);
//
//        size_t read_size = READ_CHUNK_SIZE;
//        if (fp != NULL)
//        {
//            while (read_size == READ_CHUNK_SIZE)
//            {
//                read_size = fread(buf, sizeof(uint8_t), READ_CHUNK_SIZE, fp);
//                CC_MD5_Update(&md5, buf, read_size);
//            }
//        }
//        else
//        {
//            NSLog(@"Unable to read file: %@", fileName);
//            return nil;
//        }
//
//        uint8_t digest[CC_MD5_DIGEST_LENGTH];
//        CC_MD5_Final(digest, &md5);
//
//        NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
//        for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
//            [output appendFormat:@"%02x", digest[i]];
//
//        return output;
//    }
}
