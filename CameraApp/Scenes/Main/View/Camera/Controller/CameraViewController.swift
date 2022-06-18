//
//  CameraViewController.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit

class CameraViewController: UIViewController {

    // MARK: PROPERTIES -
    
    var viewModel = CameraViewModel()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let cameraPreviewView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    lazy var permissionView: CustomPermissionView = {
        let view = CustomPermissionView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    // MARK: MAIN -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
        
        viewModel.delegate = self
        viewModel.appDelegate = appDelegate
        
        for i in 0..<viewModel.cameraOptions.count {
            let optionView = viewModel.createCameraOptions(with: viewModel.cameraOptions[i], with: i)
            optionStackView.addArrangedSubview(optionView)
            NSLayoutConstraint.activate([
                optionView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
                optionView.heightAnchor.constraint(equalToConstant: AppConstants.camera_option_Height)
            ])
        }
        
        checkPermissions()
        viewModel.lastZoomFactor = 1.0
        guard self.appDelegate.camera != nil else { return }
        self.appDelegate.camera.cameraDevice.changeCurrentZoomFactor(1.0)
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        view.backgroundColor = .black
        view.addSubview(cameraPreviewView)
        view.addSubview(optionStackView)
        view.addSubview(cameraButtonView)
        view.addSubview(sliderConfigView)
        view.addSubview(countDownTimerView)
        view.addSubview(permissionView)
    }
    
    func setUpConstraints(){
        cameraPreviewView.pin(to: view)
        sliderConfigView.pin(to: view)
        countDownTimerView.pin(to: view)
        permissionView.pin(to: view)
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
            print("Start Recording")
            startRecordingVideo()
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.optionStackView.alpha = 0
            } completion: { finished in
                self.optionStackView.isHidden = true
            }
        } else {
            print("Stop Recording")
            finishAndProcessTheVideo()
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
