//
//  MainViewController.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: PROPERTIES -
    
    var viewModel = CameraViewModel()
    
    let backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "demo")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let optionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var sliderConfigView: CustomSliderView = {
        let view = CustomSliderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.delegate = self
        view.viewModel = self.viewModel
        return view
    }()
    
    // MARK: MAIN -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
        
        viewModel.delegate = self
        
        for i in 0..<viewModel.cameraOptions.count {
            let optionView = viewModel.createCameraOptions(with: viewModel.cameraOptions[i], with: i)
            optionStackView.addArrangedSubview(optionView)
            NSLayoutConstraint.activate([
                optionView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
                optionView.heightAnchor.constraint(equalToConstant: AppConstants.camera_option_Height)
            ])
        }
        
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        view.backgroundColor = .black
        view.addSubview(backgroundImage)
        view.addSubview(optionStackView)
        view.addSubview(sliderConfigView)
    }
    
    func setUpConstraints(){
        backgroundImage.pin(to: view)
        sliderConfigView.pin(to: view)
        NSLayoutConstraint.activate([
            optionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            optionStackView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
        ])
    }
    
}

extension MainViewController: CameraViewModelActionDelegate, CustomSliderActionDelegate {
    
    func didCameraOptionTapped(with tag: Int, updateEvent: Bool) {
        let view = optionStackView.subviews
        for view in view {
            if let view = view as? CameraOptionView {
                if view.tag == tag {
                    if !updateEvent { view.tapInteraction() }
                    viewModel.optionTapped(with: tag, view: view, sliderView: sliderConfigView, updateEvent: updateEvent)
                }
            }
        }
    }
    
    func didConfirmValueChangeTapped(with data: SliderData) {
        if data.type == .speed {
            didCameraOptionTapped(with: 3, updateEvent: true)
        } else {
            didCameraOptionTapped(with: 2, updateEvent: true)
        }
    }
    
}
