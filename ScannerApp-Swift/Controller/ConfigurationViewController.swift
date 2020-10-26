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
    
    @IBOutlet weak var hostnameTextField: UITextField!
    @IBOutlet weak var portTextField: UITextField!
    
    @IBOutlet weak var debugModeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup text fields
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        hostnameTextField.delegate = self
        portTextField.delegate = self
        
        firstNameTextField.text = UserDefaults.firstName
        lastNameTextField.text = UserDefaults.lastName
        
        hostnameTextField.text = UserDefaults.hostname
        portTextField.text = UserDefaults.port
        
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
        case hostnameTextField:
            print("setting server address.")
            UserDefaults.set(hostname: text)
        case portTextField:
            print("setting port.")
            UserDefaults.set(port: text)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
    }
}
