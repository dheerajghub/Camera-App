//
//  CustomPermissionView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import UIKit

protocol CustomPermissionViewActionDelegate {
    func didEnableCameraPermissionTapped()
    func didEnableMicrophonePermissionTapped()
}

class CustomPermissionView: UIView {

    // MARK: PROPERTIES -
    
    var delegate: CustomPermissionViewActionDelegate?
    
    let permissionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()
    
    lazy var micPermissionView: PermissionOptionView = {
        let view = PermissionOptionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.permissionTypeLabel.text = "Enable Microphone Access!"
        view.permissionTypeImage.image = UIImage(systemName: "mic.circle.fill")?.withRenderingMode(.alwaysOriginal)
//        view.permissionTypeImage.
        view.actionButton.addTarget(self, action: #selector(micPermissionTapped), for: .touchUpInside)
        
        return view
    }()
    
    lazy var cameraPermissionView: PermissionOptionView = {
        let view = PermissionOptionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        view.permissionTypeLabel.text = "Enable Camera Access!"
        view.permissionTypeImage.image = UIImage(systemName: "camera.circle.fill")?.withRenderingMode(.alwaysOriginal)
        view.actionButton.addTarget(self, action: #selector(cameraPermissionTapped), for: .touchUpInside)
        
        return view
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        backgroundColor = .black.withAlphaComponent(0.8)
        addSubview(permissionStackView)
        
        permissionStackView.addArrangedSubview(cameraPermissionView)
        permissionStackView.addArrangedSubview(micPermissionView)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            permissionStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            permissionStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            permissionStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            permissionStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            
            micPermissionView.heightAnchor.constraint(equalToConstant: 40),
            cameraPermissionView.heightAnchor.constraint(equalToConstant: 40)
            
        ])
    }
    
    // MARK: - ACTIONS
    
    @objc func cameraPermissionTapped() {
        delegate?.didEnableCameraPermissionTapped()
    }
    
    @objc func micPermissionTapped() {
        delegate?.didEnableMicrophonePermissionTapped()
    }

}

class PermissionOptionView: UIView {
    
    // MARK: PROPERTIES -
    
    let permissionTypeImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "camera.circle.fill")
        imageView.tintColor = Colors.lightGreen
        return imageView
    }()
    
    let permissionTypeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Enable Camera Permission!"
        label.font = .systemFont(ofSize: 17, weight: .regular)
        return label
    }()
    
    let actionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Enable", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Colors.lightGreen
        button.layer.cornerRadius = 20
        return button
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(permissionTypeImage)
        addSubview(permissionTypeLabel)
        addSubview(actionButton)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            permissionTypeImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            permissionTypeImage.widthAnchor.constraint(equalToConstant: 40),
            permissionTypeImage.heightAnchor.constraint(equalToConstant: 40),
            permissionTypeImage.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            permissionTypeLabel.leadingAnchor.constraint(equalTo: permissionTypeImage.trailingAnchor, constant: 10),
            permissionTypeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            permissionTypeLabel.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -10),
            
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 80),
            actionButton.heightAnchor.constraint(equalToConstant: 40),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
}
