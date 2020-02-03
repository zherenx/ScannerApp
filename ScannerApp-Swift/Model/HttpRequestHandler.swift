//
//  HttpRequestHandler.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-29.
//  Copyright © 2019 jx16. All rights reserved.
//

import Foundation

protocol HttpRequestHandlerDelegate {
    func didReceiveUploadProgressUpdate(progress: Float)
    func didCompleteUpload(data: Data?,response: URLResponse?, error: Error?)
}

class HttpRequestHandler: NSObject {
    
//    private let host = URL(string: "http://192.168.1.66:5000/upload")!
    private let host = URL(string: "http://aspis.cmpt.sfu.ca/multiscan/upload")!
    private let uploadQueue = OperationQueue()
    var httpRequestHandlerDelegate: HttpRequestHandlerDelegate?
    
    // TODO: return type should be whatever http response code type is
    func upload(toUpload url: URL) {
        
//        if url.isFileURL {
//
//            print("hello")
//
//            uploadOneFile(url: url)
//        } else {
//
//            print("world")
//
//            uploadAllFilesInDir(dirUrl: url)
//        }
        
        if url.hasDirectoryPath {
            uploadAllFilesInDir(dirUrl: url)
        } else {
            uploadOneFile(url: url)
        }
        
    }
    
    func uploadOneFile(url: URL) {
        var request = URLRequest(url: host)
        request.allowsCellularAccess = false
        
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(url.lastPathComponent, forHTTPHeaderField: "filename")
        
        request.httpMethod = "PUT"
        request.setValue("application/ipad_scanner_data", forHTTPHeaderField: "Content-Type")
        request.setValue(url.lastPathComponent, forHTTPHeaderField: "FILE_NAME")
        
        
        //        var config = URLSessionConfiguration.background(withIdentifier: "url session")
        //        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: uploadQueue)
        let task = session.uploadTask(with: request, fromFile: url, completionHandler: {
            data, response, error in
            
            if let delegate = self.httpRequestHandlerDelegate {
                delegate.didCompleteUpload(data: data, response: response, error: error)
            } else {
                print("Upload complete")
                
                if let error = error {
                    print ("error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                        print ("server error")
                        return
                }
                if let mimeType = response.mimeType,
                    mimeType == "application/json",
                    let data = data,
                    let dataString = String(data: data, encoding: .utf8) {
                    print ("got data: \(dataString)")
                }
            }
            
        })
        
        task.resume()
    }
    
    func uploadAllFilesInDir(dirUrl: URL) {
        
        var fileURLs: [URL] = []
        
        do {
            fileURLs = try FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: nil)
            
        } catch {
            print("Error while enumerating files \(dirUrl.path): \(error.localizedDescription)")
        }
        
//        uploadOneFile(url: fileURLs[0])
//        print(fileURLs[0])
        
        for url in fileURLs {
            uploadOneFile(url: url)
        }
        
    }
    
}

extension HttpRequestHandler: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("Session has been invalidated")
        if let error = error {
            print ("error: \(error)")
            return
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("All messages enqueued for a session have been delivered")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Task finished transferring data")
        if let error = error {
            print ("error: \(error)")
            return
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let uploadProgress: Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        if let delegate = httpRequestHandlerDelegate {
            delegate.didReceiveUploadProgressUpdate(progress: uploadProgress)
        } else {
            print(uploadProgress)
        }
    }
}
