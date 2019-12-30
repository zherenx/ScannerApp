//
//  HttpRequestHandlerAPI.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-29.
//  Copyright © 2019 jx16. All rights reserved.
//

import Foundation

struct HttpRequestHandlerAPI {
    
    static let host = URL(string: "http://192.168.1.69:5000/upload")!
    
    // TODO: return type should be whatever http response code type is
    static func upload(toUpload fileUrl: URL) -> Int {
        
        var request = URLRequest(url: host)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(fileUrl.lastPathComponent, forHTTPHeaderField: "filename")
        
        let task = URLSession.shared.uploadTask(with: request, fromFile: fileUrl) { data, response, error in
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
        
        task.resume()
        
        // TODO: return status
        return 0
    }
}
