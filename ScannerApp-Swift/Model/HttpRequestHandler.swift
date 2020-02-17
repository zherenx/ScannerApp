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
    func didCompletedUploadWithError()
    func didCompletedUploadWithoutError()
}

class HttpRequestHandler: NSObject {

    private let host = Constants.Server.host
    private let uploadEndpoint = Constants.Server.Endpoints.upload
    private let verifyEndpoint = Constants.Server.Endpoints.verify
    
    private let uploadQueue = OperationQueue()
    
    private let uploadUrl: URL!
    private var verifyUrl: URLComponents!
    
    let httpRequestHandlerDelegate: HttpRequestHandlerDelegate!
    
    init(delegate: HttpRequestHandlerDelegate) {
        uploadUrl = URL(string: host + uploadEndpoint)
        verifyUrl = URLComponents(string: host + verifyEndpoint)
        httpRequestHandlerDelegate = delegate
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
        
        request.httpMethod = "PUT"
        request.setValue("application/ipad_scanner_data", forHTTPHeaderField: "Content-Type")
        request.setValue(url.lastPathComponent, forHTTPHeaderField: "FILE_NAME")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: uploadQueue)
        let task = session.uploadTask(with: request, fromFile: url, completionHandler: {
            data, response, error in
            
            guard let httpUrlResponse = response as? HTTPURLResponse,
                (200...299).contains(httpUrlResponse.statusCode) else {
                    
                    print("failed to upload \(url.absoluteString)")
                    print(response.debugDescription)
                    
                    self.httpRequestHandlerDelegate.didCompletedUploadWithError()
                    
                    return
            }
            
        })
        
        task.resume()
    }
    
    func uploadAllFilesInDir(dirUrl: URL) {
        
        let fileURLs = getFilesInDirectorySortedByFileSize(dirUrl: dirUrl)
        
        uploadAllFilesOneByOne(fileURLs: fileURLs)
    }
    
    private func getFilesInDirectorySortedByFileSize(dirUrl: URL) -> [URL] {
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
        
        return fileURLs
    }
    
    func uploadAllFilesOneByOne(fileURLs: [URL]) {
        if fileURLs.isEmpty {
            if let delegate = self.httpRequestHandlerDelegate {
                delegate.didCompletedUploadWithoutError()
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
            
            guard let httpUrlResponse = response as? HTTPURLResponse,
                (200...299).contains(httpUrlResponse.statusCode) else {
                    
                    print("failed to upload \(currentFileUrl.absoluteString)")
                    print(response.debugDescription)
                    
                    self.httpRequestHandlerDelegate.didCompletedUploadWithError()
                    
                    return
            }
            
            print("uploaded \(currentFileUrl.lastPathComponent)")
            
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

            let verifyTask = session.dataTask(with: verifyRequest, completionHandler: {
                data, response, error in
                
                guard let httpUrlResponse = response as? HTTPURLResponse,
                    (200...299).contains(httpUrlResponse.statusCode) else {
                        
                        print("failed to verify \(currentFileUrl.absoluteString)")
                        print(response.debugDescription)
                        
                        self.httpRequestHandlerDelegate.didCompletedUploadWithError()
                        
                        return
                }
                
                print("verified \(currentFileUrl.lastPathComponent)")
                
                var newFileList = fileURLs
                newFileList.remove(at: 0)
                self.uploadAllFilesOneByOne(fileURLs: newFileList)
            })
            
            verifyTask.resume()
        })
        
        uploadTask.resume()
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
