//
//  CameraViewController+Delegates.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 11/06/22.
//

import UIKit
import AVFoundation

extension CameraViewController: CameraViewModelActionDelegate, CustomSliderActionDelegate, CameraButtonViewActionDelegate, CustomPermissionViewActionDelegate {
    
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
    
}
