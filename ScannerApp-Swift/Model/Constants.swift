//
//  Constants.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-13.
//  Copyright © 2020 jx16. All rights reserved.
//

struct Constants {
    
//    static let sceneTypes: [String] = ["Please Select A Scene Type",
//                                       "Dining Room",
//                                       "Office",
//                                       "Classroom",
//                                       "Bedroom / Hotel",
//                                       "Living room / Lounge",
//                                       "Kitchen",
//                                       "Bookstore / Library",
//                                       "Bathroom",
//                                       "Conference Room",
//                                       "Misc."]
    
    static let sceneTypes: [String] = ["Please Select A Scene Type",
                                       "Apartment",
                                       "Bathroom",
                                       "Bedroom / Hotel",
                                       "Bookstore / Library",
                                       "Classroom",
                                       "Closet",
                                       "ComputerCluster",
                                       "Conference Room",
                                       "Copy Room",
                                       "Copy/Mail Room",
                                       "Dining Room",
                                       "Game room",
                                       "Gym",
                                       "Hallway",
                                       "Kitchen",
                                       "Laundromat",
                                       "Laundry Room",
                                       "Living room / Lounge",
                                       "Lobby",
                                       "Mailboxes",
                                       "Misc.",
                                       "Office",
                                       "Stairs",
                                       "Storage/Basement/Garage"]
    
    struct Sensor {
        struct Imu {
            struct RotationRate {
                static let type: String = "rot"
                static let fileExtension: String = "rot"
            }
            
            struct UserAcceleration {
                static let type: String = "acce"
                static let fileExtension: String = "acce"
            }
            
            struct MagneticField {
                static let type: String = "mag"
                static let fileExtension: String = "mag"
            }
            
            struct Attitude {
                static let type: String = "atti"
                static let fileExtension: String = "atti"
            }
            
            struct Gravity {
                static let type: String = "grav"
                static let fileExtension: String = "grav"
            }
            
            static let frequency = 60
            static let encoding = "bin"
        }
        
//        struct Camera {
//            static let frequency = 30
//            static let encoding = "h264"
//        }
    }
    
    struct Server {
        
        static let chuckSize = 4096
        
        struct Endpoints {
            static let upload: String = "/upload"
            static let verify: String = "/verify"
        }

        static let host: String = "http://aspis.cmpt.sfu.ca/multiscan"
//        static let host: String = "http://192.168.1.66:5000"
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
