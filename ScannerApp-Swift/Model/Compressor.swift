// This file is based on and copied from apple's sample app Compression-Streaming-Sample

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains static functions for streaming encode and decode.
*/

import Foundation
import Compression

class Compressor {
    static func streamingCompression(operation: compression_stream_operation,
                                     sourceFileHandle: FileHandle,
                                     destinationFileHandle: FileHandle,
                                     algorithm: compression_algorithm,
                                     progressUpdateFunction: (Int64) -> Void) {
        
        let bufferSize = 32_768
        let destinationBufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            destinationBufferPointer.deallocate()
        }
        
        // Create the compression_stream and throw an error if failed
        var stream = compression_stream()
        var status = compression_stream_init(&stream, operation, algorithm)
        guard status != COMPRESSION_STATUS_ERROR else {
            fatalError("Unable to initialize the compression stream.")
        }
        defer {
            compression_stream_destroy(&stream)
        }
        
        // Stream setup after compression_stream_init
        // It is indeed important to do it after, since compression_stream_init will zero all fields in stream
        stream.src_size = 0
        stream.dst_ptr = destinationBufferPointer
        stream.dst_size = bufferSize
        
        var sourceData: Data?
        repeat {
            var flags = Int32(0)
            
            // If this iteration has consumed all of the source data,
            // read a new tempData buffer from the input file.
            if stream.src_size == 0 {
                sourceData = sourceFileHandle.readData(ofLength: bufferSize)
                
                stream.src_size = sourceData!.count
                if sourceData!.count < bufferSize {
                    flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
                }
            }
            
            // Perform compression or decompression.
            if let sourceData = sourceData {
                let count = sourceData.count
                
                sourceData.withUnsafeBytes {
                    let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress!
                    
                    stream.src_ptr = baseAddress.advanced(by: count - stream.src_size)
                    status = compression_stream_process(&stream, flags)
                }
            }
            
            switch status {
            case COMPRESSION_STATUS_OK,
                 COMPRESSION_STATUS_END:
                
                // Get the number of bytes put in the destination buffer. This is the difference between
                // stream.dst_size before the call (here bufferSize), and stream.dst_size after the call.
                let count = bufferSize - stream.dst_size
                
                let outputData = Data(bytesNoCopy: destinationBufferPointer,
                                      count: count,
                                      deallocator: .none)
                
                // Write all produced bytes to the output file.
                destinationFileHandle.write(outputData)
                
                // Reset the stream to receive the next batch of output.
                stream.dst_ptr = destinationBufferPointer
                stream.dst_size = bufferSize
                progressUpdateFunction(Int64(sourceFileHandle.offsetInFile))
            case COMPRESSION_STATUS_ERROR:
                print("COMPRESSION_STATUS_ERROR.")
                return
                
            default:
                break
            }
            
        } while status == COMPRESSION_STATUS_OK
        
        sourceFileHandle.closeFile()
        destinationFileHandle.closeFile()
    }

}

extension compression_algorithm {
    var name: String {
        switch self {
        case COMPRESSION_LZ4:
            return "lz4"
        case COMPRESSION_ZLIB:
            return "zlib"
        case COMPRESSION_LZMA:
            return "lzma"
        case COMPRESSION_LZ4_RAW:
            return "lz4_raw"
        case COMPRESSION_LZFSE:
            return "lzfse"
        default:
            fatalError("Unknown compression algorithm.")
        }
    }
    
    var pathExtension: String {
        return "." + name
    }
    
    init?(name: String) {
        switch name.lowercased() {
        case "lz4":
            self = COMPRESSION_LZ4
        case "zlib":
            self = COMPRESSION_ZLIB
        case "lzma":
            self = COMPRESSION_LZMA
        case "lzfse":
            self = COMPRESSION_LZFSE
        default:
            return nil
        }
    }
}

extension compression_stream {
    init() {
        self = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1).pointee
    }
}
