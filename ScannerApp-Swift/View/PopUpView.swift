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
    
    init(firstName: String, lastName: String, description: String, sceneTypeIndex: Int) {
        
        self.firstName = firstName
        self.lastName = lastName
        self.userInputDescription = description
        self.sceneTypeIndex = sceneTypeIndex
        
//        let frame = CGRect(x: 0, y: 0, width: <#T##Int#>, height: <#T##Int#>)
        super.init(frame: .zero)
        
//        self.backgroundColor = .white
//        self.alpha = 1
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let firstNameLabel: UILabel = {
        let lb = UILabel()
        lb.text = "First Name"
        return lb
    }()
    
    let lastNameLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Last Name"
        return lb
    }()
    
    let descriptionLabel: UILabel = {
        let lb = UILabel()
        lb.text = "Description"
        return lb
    }()
    
//    let sceneTypeLabel: UILabel = {
//        let lb = UILabel()
//        lb.text = "Scene Type"
//        return lb
//    }()
    
    let firstNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter first name"
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        return tf
    }()
    
    let lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter last name"
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        return tf
    }()
    
    let descriptionTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter scene description"
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        return tf
    }()
    
//    lazy var selectSceneTypeButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setTitle(sceneTypes[sceneTypeIndex], for: .normal)
//        return btn
//    }()
    
    lazy var sceneTypePickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.delegate = self
        pv.dataSource = self
//        pv.isHidden = true
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
        btn.isEnabled = false
        return btn
    }()
    
    func setupViews() {
        
//        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: 420).isActive = true
        self.widthAnchor.constraint(equalToConstant: 330).isActive = true
        self.backgroundColor = UIColor(white: 1, alpha: 0.8)
        
        // first name row
        addSubview(firstNameLabel)
        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
        firstNameLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        firstNameLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        firstNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        firstNameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        
        addSubview(firstNameTextField)
        firstNameTextField.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextField.heightAnchor.constraint(equalTo: firstNameLabel.heightAnchor).isActive = true
        firstNameTextField.topAnchor.constraint(equalTo: firstNameLabel.topAnchor).isActive = true
        firstNameTextField.leftAnchor.constraint(equalTo: firstNameLabel.rightAnchor, constant: 8).isActive = true
        firstNameTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true

        // last name row
        addSubview(lastNameLabel)
        lastNameLabel.translatesAutoresizingMaskIntoConstraints = false
        lastNameLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        lastNameLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        lastNameLabel.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 8).isActive = true
        lastNameLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        
        addSubview(lastNameTextField)
        lastNameTextField.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextField.heightAnchor.constraint(equalTo: lastNameLabel.heightAnchor).isActive = true
        lastNameTextField.topAnchor.constraint(equalTo: lastNameLabel.topAnchor).isActive = true
        lastNameTextField.leftAnchor.constraint(equalTo: lastNameLabel.rightAnchor, constant: 8).isActive = true
        lastNameTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        
        // description row
        addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        descriptionLabel.widthAnchor.constraint(equalToConstant: 90).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: lastNameLabel.bottomAnchor, constant: 8).isActive = true
        descriptionLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true

        addSubview(descriptionTextField)
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextField.heightAnchor.constraint(equalTo: descriptionLabel.heightAnchor).isActive = true
        descriptionTextField.topAnchor.constraint(equalTo: descriptionLabel.topAnchor).isActive = true
        descriptionTextField.leftAnchor.constraint(equalTo: descriptionLabel.rightAnchor, constant: 8).isActive = true
        descriptionTextField.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        
        addSubview(sceneTypePickerView)
        sceneTypePickerView.translatesAutoresizingMaskIntoConstraints = false
        sceneTypePickerView.heightAnchor.constraint(equalToConstant: 180).isActive = true
        sceneTypePickerView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8).isActive = true
        sceneTypePickerView.leftAnchor.constraint(equalTo: leftAnchor, constant: 8).isActive = true
        sceneTypePickerView.rightAnchor.constraint(equalTo: rightAnchor, constant: -8).isActive = true
        
        addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        cancelButton.topAnchor.constraint(equalTo: sceneTypePickerView.bottomAnchor, constant: 8).isActive = true
        cancelButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: centerXAnchor, constant: -20).isActive = true
        cancelButton.backgroundColor = .yellow
        
        addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        startButton.topAnchor.constraint(equalTo: sceneTypePickerView.bottomAnchor, constant: 8).isActive = true
        startButton.leftAnchor.constraint(equalTo: centerXAnchor, constant: 20).isActive = true
        startButton.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        startButton.backgroundColor = .yellow
        
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
//        selectSceneTypeButton.setTitle(sceneTypes[row], for: .normal)
        
//        updateSceneType()
//        updateStartButton()
    }
}

