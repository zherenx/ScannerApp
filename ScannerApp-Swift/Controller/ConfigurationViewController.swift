//
//  ConfigurationViewController.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-02-09.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit

class ConfigurationViewController: UIViewController {
    
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
        
        let firstName = UserDefaults.firstName
        let lastName = UserDefaults.lastName
        
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
        
        let text: String = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        
        switch textField.tag {
        case Constants.Tag.firstNameTag:
            UserDefaults.set(firstName: text)
        case Constants.Tag.lastNameTag:
            UserDefaults.set(lastName: text)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
    }
}
