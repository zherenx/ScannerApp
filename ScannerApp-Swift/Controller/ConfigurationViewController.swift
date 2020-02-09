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
    
    private let firstNameKey = "firstName"
    private let lastNameKey = "lastName"
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        
        setupUI()
    }
    
    private func setupUI() {
        
        let firstName = defaults.string(forKey: firstNameKey)
        let lastName = defaults.string(forKey: lastNameKey)
        
        firstNameTextField.text = firstName
        lastNameTextField.text = lastName
    }
    
    private func saveUserDefaults() {
        
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
        
//        setupUI()
    }


}

extension ConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        saveUserDefaults()
        
        return true
    }
}
