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
    func didCompleteWithoutError()
}

class HttpRequestHandler: NSObject {

    private let host = Constants.Server.host
    private let uploadEndpoint = Constants.Server.Endpoints.upload
    private let verifyEndpoint = Constants.Server.Endpoints.verify
    
    private let uploadQueue = OperationQueue()
    
//    private let host = URL(string: "http://192.168.1.66:5000/upload")!
    private let uploadUrl: URL!
    private var verifyUrl: URLComponents!
    
    var httpRequestHandlerDelegate: HttpRequestHandlerDelegate?
    
    override init() {
        uploadUrl = URL(string: host + uploadEndpoint)
        verifyUrl = URLComponents(string: host + verifyEndpoint)
    }
    
    func upload(toUpload url: URL) {
        
        if url.hasDirectoryPath {
            uploadAllFilesInDir(dirUrl: url)
        } else {
            uploadOneFile(url: url)
        }
        
    }
    
    func uploadOneFile(url: URL) {
        var request = URLRequest(url: uploadUrl)
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
            fileURLs = try FileManager.default.contentsOfDirectory(at: dirUrl, includingPropertiesForKeys: [.fileSizeKey])
            
            fileURLs = fileURLs.sorted(by: { (url1: URL, url2: URL) -> Bool in
                do {
                    let size1 = try url1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    let size2 = try url2.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    return size1 < size2
                } catch {
                    print(error.localizedDescription)
                }
                print("some problem")
                return true
            })
            
        } catch {
            print("Error while enumerating files \(dirUrl.path): \(error.localizedDescription)")
        }
        
//        uploadOneFile(url: fileURLs[0])
//        print(fileURLs[0])
        
//        for url in fileURLs {
//            uploadOneFile(url: url)
//        }
        
        
        
        uploadAllFilesOneByOne(fileURLs: fileURLs)
    }
    
    func uploadAllFilesOneByOne(fileURLs: [URL]) {
        if fileURLs.isEmpty {
            if let delegate = self.httpRequestHandlerDelegate {
                delegate.didCompleteWithoutError()
            }
            return
        }
        
        let currentFileUrl = fileURLs[0]
        
        var uploadRequest = URLRequest(url: uploadUrl)
        uploadRequest.allowsCellularAccess = false
        
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue("application/ipad_scanner_data", forHTTPHeaderField: "Content-Type")
        uploadRequest.setValue(currentFileUrl.lastPathComponent, forHTTPHeaderField: "FILE_NAME")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: uploadQueue)
        let uploadTask = session.uploadTask(with: uploadRequest, fromFile: currentFileUrl, completionHandler: {
            data, response, error in
            
            print("reach completion handler")
            print(currentFileUrl)
            
            guard let response1 = response as? HTTPURLResponse,
                (200...299).contains(response1.statusCode) else {
                    
                    print("upload return error")
                    print(response.debugDescription)
                    
                    if let delegate = self.httpRequestHandlerDelegate {
                        delegate.didCompleteUpload(data: data, response: response, error: error)
                    }
                    return
            }
            
            // verify newly uploaded file
            var queryItems = [URLQueryItem]()
            let params = ["filename": currentFileUrl.lastPathComponent, "checksum": Helper.calculateChecksum(url: currentFileUrl)]
            for (key,value) in params {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            
            self.verifyUrl.queryItems = queryItems
            
            var verifyRequest = URLRequest(url: self.verifyUrl.url!)
            verifyRequest.allowsCellularAccess = false
            verifyRequest.httpMethod = "GET"
            
//            verifyRequest.setValue(currentFileUrl.lastPathComponent, forHTTPHeaderField: "filename")
//            verifyRequest.setValue(Helper.calculateChecksum(url: currentFileUrl), forHTTPHeaderField: "checksum")

            let verifyTask = session.dataTask(with: verifyRequest, completionHandler: {
                data, response, error in
                
                print("reach verify")
                
                guard let response1 = response as? HTTPURLResponse,
                    (200...299).contains(response1.statusCode) else {
                        
                        print("verify has failed")
                        print(response.debugDescription)
                        
                        if let delegate = self.httpRequestHandlerDelegate {
                            delegate.didCompleteUpload(data: data, response: response, error: error)
                        }
                        return
                }
                
                print("verify success")
                
                var newFileList = fileURLs
                newFileList.remove(at: 0)
                self.uploadAllFilesOneByOne(fileURLs: newFileList)
            })
            
            verifyTask.resume()
        })
        
        uploadTask.resume()
    }
    
    func verifyUpload(url: URL) {
        
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
