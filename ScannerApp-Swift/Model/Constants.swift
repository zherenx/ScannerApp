//
//  Constants.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-13.
//  Copyright © 2020 jx16. All rights reserved.
//

struct Constants {
    
    // this struct stores the encoding code (String) used in this project
    // and in the output files of this project (e.g. metadata)
    // the purpose of this is mainly for consistency
    struct EncodingCode {
        static let ascii: String = "ascii"
        static let binary: String = "bin"
        static let h264: String = "h264"
    }
    
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
            
            // ??
            // I think it doesn't make too much sense to include 'encoding' as a config param
            // because we will not be able to change the encoding by just changing this param here
//            static let encoding = "bin"
        }
        
        struct Camera {
            static let type = "color_camera"
            static let fileExtension: String = "mp4"
            static let frequency = 30
//            static let encoding = "h264"
        }
    }
    
    struct Server {
        
        static let chuckSize = 4096
        
        struct Endpoints {
            static let upload: String = "/upload"
            static let verify: String = "/verify"
        }

        static let defaultHost: String = "aspis.cmpt.sfu.ca/multiscan"
        static let defaultPort: String = "8000"
    }
    
    struct Tag {
        static let firstNameTag = 100
        static let lastNameTag = 200
        static let descriptionTag = 300
    }
}
