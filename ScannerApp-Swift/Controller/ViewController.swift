//
//  ViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2019-12-20.
//  Copyright © 2019 jx16. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    private let defaults = UserDefaults.standard
    
    private let firstNameKey = "firstName"
    private let lastNameKey = "lastName"
    
    private var firstName: String?
    private var lastName: String?
    
    private var roomType: String?

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var dualCamButton: UIButton!
    @IBOutlet weak var CameraButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        dualCamButton.isEnabled = false
//        if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported {
//            dualCamButton.isEnabled = true
//        }
        
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        setupUI()
    }
    
    private func setupUI() {
        
        firstName = defaults.string(forKey: firstNameKey)
        lastName = defaults.string(forKey: lastNameKey)
        
        dualCamButton.isEnabled = false
        CameraButton.isEnabled = false
        if firstName != nil && lastName != nil {
            CameraButton.isEnabled = true
            
            if #available(iOS 13.0, *), AVCaptureMultiCamSession.isMultiCamSupported {
                dualCamButton.isEnabled = true
            }
        }
        
        firstNameTextField.text = firstName
        lastNameTextField.text = lastName
    }
    
    private func saveUserDefaultsAndRefreshUI() {
        
        var newFirstName = firstNameTextField.text?.trimmingCharacters(in: .whitespaces)
        var newLastName = lastNameTextField.text?.trimmingCharacters(in: .whitespaces)

        if newFirstName != nil && newFirstName!.isEmpty {
            newFirstName = nil
        }

        if newLastName != nil && newLastName!.isEmpty {
            newLastName = nil
        }
        
        defaults.set(newFirstName, forKey: firstNameKey)
        defaults.set(newLastName, forKey: lastNameKey)
        
        setupUI()
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        saveUserDefaultsAndRefreshUI()
        
        return true
    }
}
