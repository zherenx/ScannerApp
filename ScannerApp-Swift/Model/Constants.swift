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
    
    struct UserDefaultsKeys {
        static let firstNameKey = "firstName"
        static let lastNameKey = "lastName"
        static let sceneTypeKey = "sceneType"
        static let userInputDescriptionKey = "userInputDescription"
    }
}
