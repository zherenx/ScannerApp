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
    
    private let firstNameKey = Constants.UserDefaultsKeys.firstNameKey
    private let lastNameKey = Constants.UserDefaultsKeys.lastNameKey
    
    private let sceneTypeIndexKey = Constants.UserDefaultsKeys.sceneTypeIndexKey
    private let sceneTypeKey = Constants.UserDefaultsKeys.sceneTypeKey
    
    private let sceneTypes = Constants.sceneTypes
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!

    @IBOutlet weak var selectSceneTypeButton: UIButton!
    
    @IBOutlet weak var sceneTypePickerView: UIPickerView!
    
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
        
        // setup picker view
        sceneTypePickerView.delegate = self
        sceneTypePickerView.dataSource = self

        sceneTypePickerView.isHidden = true
        
        let currentSceneTypeIndex = defaults.integer(forKey: sceneTypeIndexKey)
        selectSceneTypeButton.setTitle(sceneTypes[currentSceneTypeIndex], for: .normal)
        
        sceneTypePickerView.selectRow(currentSceneTypeIndex, inComponent: 0, animated: false)
    }

    @IBAction func selectSceneTypeButtonTapped(_ sender: Any) {
        if sceneTypePickerView.isHidden {
            sceneTypePickerView.isHidden = false
        } else {
            sceneTypePickerView.isHidden = true
        }
    }

}

extension ConfigurationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
        
        
        return true
    }
}

extension ConfigurationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return sceneTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return sceneTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        defaults.set(row, forKey: sceneTypeIndexKey)
//        defaults.set(sceneTypes[row], forKey: sceneTypeKey)
        selectSceneTypeButton.setTitle(sceneTypes[row], for: .normal)
    }
}
