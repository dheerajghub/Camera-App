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
    
    let sliderConfigView: CustomSliderView = {
        let view = CustomSliderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
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
        NSLayoutConstraint.activate([
            optionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            optionStackView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
            
            sliderConfigView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderConfigView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderConfigView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sliderConfigView.heightAnchor.constraint(equalToConstant: windowConstant.getBottomPadding + 300.0)
        ])
    }
    
}

extension MainViewController: CameraViewModelActionDelegate {
    
    func didCameraOptionTapped(with tag: Int) {
        let view = optionStackView.subviews
        for view in view {
            if let view = view as? CameraOptionView {
                if view.tag == tag {
                    view.tapInteraction()
                    viewModel.optionTapped(with: tag, view: view, sliderView: sliderConfigView)
                }
            }
        }
    }
    
}
