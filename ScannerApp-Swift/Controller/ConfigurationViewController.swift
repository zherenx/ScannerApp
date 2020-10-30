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
        hostnameTextField.autocorrectionType = .no
        portTextField.delegate = self
        portTextField.autocorrectionType = .no
        
        firstNameTextField.text = UserDefaults.firstName
        lastNameTextField.text = UserDefaults.lastName
        
        hostnameTextField.text = UserDefaults.hostname
        hostnameTextField.placeholder = Constants.Server.defaultHost
        portTextField.text = UserDefaults.port
        portTextField.placeholder = Constants.Server.defaultPort
        
        debugModeSwitch.isOn = UserDefaults.debugFlag
        
        // dismiss keyboard when tap elsewhere
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @IBAction func debugModeSwitchValueChanged(_ sender: Any) {
        UserDefaults.set(debugFlag: debugModeSwitch.isOn)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension ConfigurationViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let text: String = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        
        switch textField {
        case firstNameTextField:
            print("setting first name to '\(text)'.")
            UserDefaults.set(firstName: text)
        case lastNameTextField:
            print("setting last name to '\(text)'.")
            UserDefaults.set(lastName: text)
        case hostnameTextField:
            print("setting server address to '\(text)'.")
            UserDefaults.set(hostname: text)
        case portTextField:
            print("setting port to '\(text)'.")
            UserDefaults.set(port: text)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("dismiss keyboard.")
        textField.resignFirstResponder()
        return true
    }
    
}
