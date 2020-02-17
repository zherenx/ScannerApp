//
//  Constants.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-13.
//  Copyright © 2020 jx16. All rights reserved.
//

struct Constants {
    
    static let sceneTypes: [String] = ["Please Select A Scene Type",
                                       "Dining Room",
                                       "Office",
                                       "Classroom",
                                       "Bedroom / Hotel",
                                       "Living room / Lounge",
                                       "Kitchen",
                                       "Bookstore / Library",
                                       "Bathroom",
                                       "Conference Room",
                                       "Misc."]
    
    struct Server {
        
        static let chuckSize = 4096
        
        struct Endpoints {
            static let upload: String = "/upload"
            static let verify: String = "/verify"
        }

        static let host: String = "http://aspis.cmpt.sfu.ca/multiscan"
//        static let host: String = "http://192.168.1.66:5000/"
    }
    
    struct Tag {
        static let firstNameTag = 100
        static let lastNameTag = 200
        static let descriptionTag = 300
    }
    
    struct UserDefaultsKeys {
        static let firstNameKey = "firstName"
        static let lastNameKey = "lastName"
        static let sceneTypeIndexKey = "sceneTypeIndex"
        static let sceneTypeKey = "sceneType"
        static let userInputDescriptionKey = "userInputDescription"
    }
}
