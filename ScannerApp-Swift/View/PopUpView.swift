//
//  PopUpView.swift
//  ScannerApp-Swift
//
//  Created by Zheren Xiao on 2020-10-21.
//  Copyright © 2020 jx16. All rights reserved.
//

import UIKit

class PopUpView: UIView {
    
    private let sceneTypes = Constants.sceneTypes

    private var firstName: String = ""
    private var lastName: String = ""
    private var userInputDescription: String = ""
    private var sceneTypeIndex = 0
//    private var sceneType: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
        initValues()
    }
    
    init(frame: CGRect, firstName: String, lastName: String, description: String, sceneTypeIndex: Int) {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let firstNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter firstname"
        return tf
    }()
    
    let lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter lastname"
        return tf
    }()
    
    let descriptionTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter scene description"
        return tf
    }()
    
    lazy var selectSceneTypeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle(sceneTypes[sceneTypeIndex], for: .normal)
        return btn
    }()
    
    lazy var sceneTypePickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.delegate = self
        pv.dataSource = self
        pv.isHidden = true
        pv.selectRow(sceneTypeIndex, inComponent: 0, animated: false)
        return pv
    }()
    
    let cancelButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Cancel", for: .normal)
        return btn
    }()
    
    let startButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Start Recording", for: .normal)
        return btn
    }()
    
    func setupLayout() {
        
    }
    
    func initValues() {
        
    }
}

extension PopUpView: UITextFieldDelegate {
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
            firstName = text
            UserDefaults.set(firstName: text)
        case Constants.Tag.lastNameTag:
            lastName = text
            UserDefaults.set(lastName: text)
        case Constants.Tag.descriptionTag:
            userInputDescription = text
            UserDefaults.set(userInputDescription: text)
        default:
            print("text field with tag \(textField.tag) is not found.")
        }
        
//        updateStartButton()
    }
}

extension PopUpView: UIPickerViewDelegate, UIPickerViewDataSource {
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
        UserDefaults.set(sceneTypeIndex: row)
        selectSceneTypeButton.setTitle(sceneTypes[row], for: .normal)
        
//        updateSceneType()
//        updateStartButton()
    }
}

