//
//  ConfigurationViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-09.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit

class ConfigurationViewController: UIViewController {

    private let defaults = UserDefaults.standard
    
    private let firstNameKey = Constants.UserDefaultsKeys.firstName
    private let lastNameKey = Constants.UserDefaultsKeys.lastName
    
    private let sceneTypeIndexKey = Constants.UserDefaultsKeys.sceneTypeIndex
    private let sceneTypeKey = Constants.UserDefaultsKeys.sceneType
    
    private let sceneTypes = Constants.sceneTypes
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup text fields
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        firstNameTextField.tag = Constants.Tag.firstNameTag
        lastNameTextField.tag = Constants.Tag.lastNameTag
        
        let firstName = defaults.string(forKey: firstNameKey)
        let lastName = defaults.string(forKey: lastNameKey)
        
        firstNameTextField.text = firstName
        lastNameTextField.text = lastName
    }

}

extension ConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldDidUpdate(textField)
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textFieldDidUpdate(textField)
        
        return true
    }
    
    private func textFieldDidUpdate(_ textField: UITextField) {
        textField.resignFirstResponder()
        
        var text = textField.text?.trimmingCharacters(in: .whitespaces)

        if text != nil && text!.isEmpty {
            text = nil
        }
        
        switch textField.tag {
        case Constants.Tag.firstNameTag:
            defaults.set(text, forKey: firstNameKey)
        case Constants.Tag.lastNameTag:
            defaults.set(text, forKey: lastNameKey)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
    }
}
