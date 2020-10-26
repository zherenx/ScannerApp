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
    
    @IBOutlet weak var serverAddressTextField: UITextField!
   
    @IBOutlet weak var debugModeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup text fields
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        serverAddressTextField.delegate = self
        
        firstNameTextField.text = UserDefaults.firstName
        lastNameTextField.text = UserDefaults.lastName
        
        serverAddressTextField.text = UserDefaults.serverAddress
        
        debugModeSwitch.isOn = UserDefaults.debugFlag
    }

    @IBAction func debugModeSwitchValueChanged(_ sender: Any) {
        UserDefaults.set(debugFlag: debugModeSwitch.isOn)
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
        
        switch textField {
        case firstNameTextField:
            print("setting first name")
            UserDefaults.set(firstName: text)
        case lastNameTextField:
            print("setting last name.")
            UserDefaults.set(lastName: text)
        case serverAddressTextField:
            print("setting server address.")
            UserDefaults.set(serverAddress: text)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
    }
}
