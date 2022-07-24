//
//  CameraViewController+Delegates.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 11/06/22.
//

import UIKit
import AVFoundation

extension CameraViewController: CameraViewModelActionDelegate, CustomSliderActionDelegate, CameraButtonViewActionDelegate, CustomPermissionViewActionDelegate , CameraTypeActionDelegate, ReelCameraButtonActionDelegate {
    
    func didReelCameraButtonTapped(with state: CameraButtonState) {
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
    
    
    func toggleCameraType(to type: CameraTypeState) {
        if type == .reel {
            if viewModel.cameraType == .video {
                /// Adding new option in stack for reel type
                let option = CameraOption(optionName: "duration", optionImage: "ic_duration")
                viewModel.cameraOptions.append(option)
                setOptionStack()
            }
            viewModel.cameraType = type
            viewModel.resetAllDefaults()
            reelCameraButtonView.nextButton.isHidden = true
            
            reelCameraButtonView.isHidden = false
            reelCameraButtonView.cameraButton.isEnabled = true
            
            videoTimerBarView.isHidden = false
            videoTimerBarView.withDuration = viewModel.recordingDuration
            videoTimerBarView.totalDuration = viewModel.recordingDuration
            videoTimerBarView.reloadViews()
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [weak self] in
                self?.cameraButtonView.alpha = 0
                self?.reelCameraButtonView.alpha = 1
                self?.videoTimerBarView.alpha = 1
            } completion: { finished in
                self.cameraButtonView.isHidden = true
            }
            

            
        } else {
            viewModel.cameraType = type
            /// Removing options in stack which are not required for video type
            var options = viewModel.cameraOptions
            for i in 0..<options.count {
                if options[i].optionName == "duration" {
                    options.remove(at: i)
                }
            }
            viewModel.cameraOptions = options
            setOptionStack()
            viewModel.resetAllDefaults()
            
            cameraButtonView.isHidden = false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) { [self] in
                cameraButtonView.alpha = 1
                reelCameraButtonView.alpha = 0
                videoTimerBarView.alpha = 0
            } completion: { finished in
                self.reelCameraButtonView.isHidden = true
                self.videoTimerBarView.isHidden = true
            }
        }
        
    }
    
    func didEnableCameraPermissionTapped() {
        enableCamera()
    }
    
    func didEnableMicrophonePermissionTapped() {
        enableMic()
    }
    
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
                        if tag == 2 || tag == 3 || tag == 4 {
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
        } else if data.type == .timer {
            didCameraOptionTapped(with: 2, updateEvent: true)
        } else {
            didCameraOptionTapped(with: 4, updateEvent: true)
        }
    }
    
    func dismissSlider() {
        setUpViews(to: .shown)
    }
    
    func didFlipCameraTapped() {
        flipCamera()
    }
    
    func toggleFlashAndTorch(for state: FlashState) {
        switch state {
        case .on:
            appDelegate.camera.torchMode = AVCaptureDevice.TorchMode.on
            appDelegate.camera.flashMode = AVCaptureDevice.FlashMode.on
        case .off:
            appDelegate.camera.torchMode = AVCaptureDevice.TorchMode.off
            appDelegate.camera.flashMode = AVCaptureDevice.FlashMode.off
        case .auto:
            appDelegate.camera.torchMode = AVCaptureDevice.TorchMode.auto
            appDelegate.camera.flashMode = AVCaptureDevice.FlashMode.auto
        }
    }
    
    func didNextButtonTapped() {
        let VC = ShortsPreviewController()
        VC.modalPresentationStyle = .fullScreen
        VC.modalTransitionStyle = .crossDissolve
        VC.videoAssets = viewModel.videoAssetsChunk
        VC.speedArr = viewModel.videoSpeedArr
        VC.viewModel = viewModel
        self.present(VC, animated: true)
    }
    
}

extension CameraViewController: CustomVideoTimerBarActionDelegate {
    
    func didVideoCompleted() {
        setUIOnCameraButtonTap(with: .active)
        reelCameraButtonView.cameraButtonView.alpha = 0.5
        reelCameraButtonView.cameraButton.isEnabled = false
        
        // Hide duration selection after video completion.
        if let durationView = optionStackView.arrangedSubviews.last as? CameraOptionView {
            durationView.alpha = 0.5
            durationView.optionActionButton.isEnabled = false
        }
    }
    
}
