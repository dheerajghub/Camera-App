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
    
    let liveCameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        return view
    }()
    
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
    
    lazy var reelCameraButtonView: ReelCameraButtonView = {
        let view = ReelCameraButtonView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        view.alpha = 0
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
    
    lazy var toggleCameraView: CameraTypeToggleView = {
        let view = CameraTypeToggleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    lazy var videoTimerBarView: CustomVideoTimerBarView = {
        let v = CustomVideoTimerBarView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.delegate = self
        v.alpha = 0
        v.isHidden = true
        return v
    }()
    
    // MARK: MAIN -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
        
        viewModel.delegate = self
        viewModel.appDelegate = appDelegate
        
        setOptionStack()
        
        checkPermissions()
        viewModel.lastZoomFactor = 1.0
        guard self.appDelegate.camera != nil else { return }
        self.appDelegate.camera.cameraDevice.changeCurrentZoomFactor(1.0)
    }
    
    deinit {
        print("CameraViewController Deinitialized.....")
        FileManager.default.clearTmpDirectory()
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        view.backgroundColor = .black
        
        view.addSubview(liveCameraView)
        liveCameraView.addSubview(cameraPreviewView)
        liveCameraView.addSubview(videoTimerBarView)
        
        view.addSubview(optionStackView)
        view.addSubview(cameraButtonView)
        view.addSubview(reelCameraButtonView)
        view.addSubview(sliderConfigView)
        view.addSubview(countDownTimerView)
        view.addSubview(permissionView)
        view.addSubview(toggleCameraView)
    }
    
    func setUpConstraints(){
        sliderConfigView.pin(to: view)
        countDownTimerView.pin(to: view)
        permissionView.pin(to: view)
        cameraPreviewView.pin(to: liveCameraView)
        NSLayoutConstraint.activate([
            liveCameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            liveCameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            liveCameraView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            liveCameraView.heightAnchor.constraint(equalToConstant: (16/9) * view.frame.size.width),
            liveCameraView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            videoTimerBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            videoTimerBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            videoTimerBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            videoTimerBarView.heightAnchor.constraint(equalToConstant: 10),
            
            optionStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            optionStackView.centerYAnchor.constraint(equalTo: cameraPreviewView.centerYAnchor),
            optionStackView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
            
            cameraButtonView.bottomAnchor.constraint(equalTo: toggleCameraView.topAnchor),
            cameraButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraButtonView.heightAnchor.constraint(equalToConstant: 120),
            
            reelCameraButtonView.bottomAnchor.constraint(equalTo: toggleCameraView.topAnchor),
            reelCameraButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reelCameraButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            reelCameraButtonView.heightAnchor.constraint(equalToConstant: 120),
            
            toggleCameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toggleCameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toggleCameraView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toggleCameraView.heightAnchor.constraint(equalToConstant: UIDevice.current.hasNotch ? 75 : 50),
        ])
    }
    
    func setOptionStack(){
        
        // Before adding anything to stack remove everything
        optionStackView.removeFullyAllArrangedSubviews()
        
        for i in 0..<viewModel.cameraOptions.count {
            let optionView = viewModel.createCameraOptions(with: viewModel.cameraOptions[i], with: i)
            optionStackView.addArrangedSubview(optionView)
            NSLayoutConstraint.activate([
                optionView.widthAnchor.constraint(equalToConstant: AppConstants.camera_option_Width),
                optionView.heightAnchor.constraint(equalToConstant: AppConstants.camera_option_Height)
            ])
        }
    }
    
    func setUIOnCameraButtonTap(with state: CameraButtonState){
        
        if viewModel.cameraType == .video {
            cameraButtonView.animateButtonWithState(with: state)
        } else {
            reelCameraButtonView.animateButtonWithState(with: state)
        }
        
        if state == .inactive {
            print("Start Recording")
            startRecordingVideo()
            setUpViews(to: .hidden, forCounter: false)
            
            if viewModel.cameraType == .reel {
                videoTimerBarView.withDuration = (viewModel.recordingDuration - (videoTimerBarView.totalDuration - videoTimerBarView.withDuration))
                videoTimerBarView.totalDuration = viewModel.recordingDuration
                videoTimerBarView.speed = viewModel.currentSpeedScale
                videoTimerBarView.startAnimatingTrackLayer(reload: false)
                videoTimerBarView.timerBarViewHeightConstraint?.constant = 10
                videoTimerBarView.timerCounterLabel.isHidden = false
                
                
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                    self?.videoTimerBarView.timerCounterLabel.alpha = 1
                    self?.reelCameraButtonView.nextButton.alpha = 0
                } completion: { finished in
                    self.reelCameraButtonView.nextButton.isHidden = true
                }
            }
            
        } else {
            print("Stop Recording")
            finishAndProcessTheVideo()
            setUpViews(to: .shown, forCounter: false)
            
            if viewModel.cameraType == .reel {
                videoTimerBarView.timerCounterLabel.isHidden = false
                videoTimerBarView.stopAnimatingTrackLayer()
                videoTimerBarView.timerBarViewHeightConstraint?.constant = 5
                reelCameraButtonView.nextButton.isHidden = false
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.view.layoutIfNeeded()
                    self?.videoTimerBarView.timerCounterLabel.alpha = 0
                    self?.reelCameraButtonView.nextButton.alpha = 1
                } completion: { finished in
                    self.videoTimerBarView.timerCounterLabel.isHidden = true
                }
            }
            
        }
        
    }
    
    func setUpViews(to state: CameraViewsState, forCounter: Bool = true) {
        if state == .hidden {
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.optionStackView.alpha = 0
                if forCounter {
                    if self?.viewModel.cameraType == .reel {
                        self?.reelCameraButtonView.alpha = 0
                    } else {
                        self?.cameraButtonView.alpha = 0
                    }
                }
                self?.toggleCameraView.alpha = 0
            } completion: { finished in
                self.optionStackView.isHidden = true
                if forCounter {
                    if self.viewModel.cameraType == .reel {
                        self.reelCameraButtonView.isHidden = true
                    } else {
                        self.cameraButtonView.isHidden = true
                    }
                }
                self.toggleCameraView.isHidden = true
            }
        } else {
            optionStackView.isHidden = false
            if forCounter {
                if viewModel.cameraType == .reel {
                    reelCameraButtonView.isHidden = false
                } else {
                    cameraButtonView.isHidden = false
                }
            }
            toggleCameraView.isHidden = false
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.optionStackView.alpha = 1
                if forCounter {
                    if self?.viewModel.cameraType == .reel {
                        self?.reelCameraButtonView.alpha = 1
                    } else {
                        self?.cameraButtonView.alpha = 1
                    }
                }
                self?.toggleCameraView.alpha = 1
            }
        }
    }
    
}
