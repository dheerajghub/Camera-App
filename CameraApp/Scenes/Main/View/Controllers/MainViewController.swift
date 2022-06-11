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
        imageView.image = UIImage(named: "demo2")
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
    
    lazy var cameraButtonView: CameraButtonView = {
        let view = CameraButtonView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    let countDownTimerView: CountDownTimerView = {
        let view = CountDownTimerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.alpha = 0
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
        view.addSubview(cameraButtonView)
        view.addSubview(sliderConfigView)
        view.addSubview(countDownTimerView)
    }
    
    func setUpConstraints(){
        backgroundImage.pin(to: view)
        sliderConfigView.pin(to: view)
        countDownTimerView.pin(to: view)
        NSLayoutConstraint.activate([
            optionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            optionStackView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
            
            cameraButtonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cameraButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraButtonView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    func setUIOnCameraButtonTap(with state: CameraButtonState){
        cameraButtonView.animateButtonWithState(with: state)
        if state == .inactive {
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.optionStackView.alpha = 0
            } completion: { finished in
                self.optionStackView.isHidden = true
            }
        } else {
            self.optionStackView.isHidden = false
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.optionStackView.alpha = 1
            }
        }
    }
    
    func setUpViews(to state: CameraViewsState) {
        if state == .hidden {
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.optionStackView.alpha = 0
                self?.cameraButtonView.alpha = 0
            } completion: { finished in
                self.optionStackView.isHidden = true
                self.cameraButtonView.isHidden = true
            }
        } else {
            optionStackView.isHidden = false
            cameraButtonView.isHidden = false
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.optionStackView.alpha = 1
                self?.cameraButtonView.alpha = 1
            }
        }
    }
    
}

extension MainViewController: CameraViewModelActionDelegate, CustomSliderActionDelegate, CameraButtonViewActionDelegate {
    
    func didCameraButtonTapped(with state: CameraButtonState) {
        if viewModel.counterFor == 0 {
            setUIOnCameraButtonTap(with: state)
        } else {
            setUpViews(to: .hidden)
            countDownTimerView.counterFor = viewModel.counterFor
            countDownTimerView.startTimer()
            countDownTimerView.isHidden = false
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.countDownTimerView.alpha = 1
            }
            countDownTimerView.callback = { [weak self] in
                self?.setUpViews(to: .shown)
                self?.viewModel.counterFor = 0
                self?.viewModel.timerData.selectedIndex = 0
                self?.didCameraOptionTapped(with: 2, updateEvent: true)
                self?.setUIOnCameraButtonTap(with: state)
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.countDownTimerView.alpha = 0
                } completion: { finished in
                    self?.countDownTimerView.isHidden = true
                }
            }
        }
        
    }
    
    func didCameraOptionTapped(with tag: Int, updateEvent: Bool) {
        let view = optionStackView.subviews
        for view in view {
            if let view = view as? CameraOptionView {
                if view.tag == tag {
                    if !updateEvent { view.tapInteraction() }
                    viewModel.optionTapped(with: tag, view: view, sliderView: sliderConfigView, updateEvent: updateEvent)
                    /// Hiding all other view when timer or speed is being configured
                    if !updateEvent {
                        if tag == 2 || tag == 3 {
                            setUpViews(to: .hidden)
                        }
                    }
                }
            }
        }
    }
    
    func didConfirmValueChangeTapped(with data: SliderData) {
        setUpViews(to: .shown)
        if data.type == .speed {
            didCameraOptionTapped(with: 3, updateEvent: true)
        } else {
            didCameraOptionTapped(with: 2, updateEvent: true)
        }
    }
    
    func dismissSlider() {
        setUpViews(to: .shown)
    }
    
}
