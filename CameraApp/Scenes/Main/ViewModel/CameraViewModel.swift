//
//  CameraViewModel.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit

protocol CameraViewModelActionDelegate {
    func didCameraOptionTapped(with tag: Int, updateEvent: Bool)
}

enum CameraViewsState {
    case hidden
    case shown
}

enum FlashState {
    case on
    case off
    case auto
}

class CameraViewModel: NSObject {
    
    var delegate: CameraViewModelActionDelegate?
    var isFlashOn = false
    var isFrontCamera = true
    var counterFor = 0
    var cameraFlashState: FlashState = .off
    
    let cameraOptions = [
        CameraOption(optionName: "flash", optionImage: "ic_flash_off"),
        CameraOption(optionName: "flip", optionImage: "ic_flip"),
        CameraOption(optionName: "timer", optionImage: "ic_timer"),
        CameraOption(optionName: "speed", optionImage: "ic_speed")
    ]
    
    var timerData = SliderData(type: .timer, names: ["0s","3s","5s","6s","8s","10s"], values: [0,3,5,6,8,10], selectedIndex: 0)
    var speedData = SliderData(type: .speed, names: ["0x","•","1x","•","2x","•","3x"], values: [0,0.5,1,1.5,2,2.5,3], selectedIndex: 0)
    
    func createCameraOptions(with data: CameraOption, with tag: Int) -> UIView {
        let view = CameraOptionView()
        view.tag = tag
        view.optionLabel.text = data.optionName.uppercased()
        view.optionActionButton.tag = tag
        view.optionActionButton.addTarget(self, action: #selector(cameraOptionTapped(_:)), for: .touchUpInside)
        view.optionImageView.image = UIImage(named: data.optionImage)?.withRenderingMode(.alwaysTemplate)
        view.optionImageView.tintColor = .white
        return view
    }
    
    func optionTapped(with type: CameraOptions.RawValue, view: CameraOptionView, sliderView: CustomSliderView , updateEvent: Bool = false) {
        let cameraOption = CameraOptions(rawValue: type) ?? .flash
        switch cameraOption {
        case .flash:
            switch cameraFlashState {
            case .on:
                view.optionImageView.image = UIImage(named: "ic_flash_auto")?.withRenderingMode(.alwaysTemplate)
                view.optionBackView.backgroundColor = .yellow
                view.optionImageView.tintColor = .black
                cameraFlashState = .auto
            case .off:
                view.optionImageView.image = UIImage(named: "ic_flash_on")?.withRenderingMode(.alwaysTemplate)
                view.optionBackView.backgroundColor = .white
                view.optionImageView.tintColor = .black
                cameraFlashState = .on
            case .auto:
                view.optionImageView.image = UIImage(named: "ic_flash_off")?.withRenderingMode(.alwaysTemplate)
                view.optionBackView.backgroundColor = .clear
                view.optionImageView.tintColor = .white
                cameraFlashState = .off
            }
            break
        case .flip:
            break
        case .timer:
            let value = timerData.values[timerData.selectedIndex]
            counterFor = Int(value)
            if updateEvent {
                if value != 0 {
                    view.optionDetailView.backgroundColor = Colors.skyBlue
                    view.optionDetailView.isHidden = false
                    view.optionDetailView.setTitle("\(Int(value))s", for: .normal)
                } else {
                    view.optionDetailView.isHidden = true
                }
            } else {
                sliderView.valuePreviewView.setTitle("Timer 0s", for: .normal)
                sliderView.openAnimation()
            }
            sliderView.sliderData = timerData
            break
        case .speed:
            let value = speedData.values[speedData.selectedIndex]
            if updateEvent {
                if value != 0 {
                    view.optionDetailView.isHidden = false
                    view.optionDetailView.backgroundColor = Colors.lightGreen
                    view.optionDetailView.setTitle("\(value)x", for: .normal)
                } else {
                    view.optionDetailView.isHidden = true
                }
            } else {
                sliderView.valuePreviewView.setTitle("Speed 0x", for: .normal)
                sliderView.openAnimation()
            }
            sliderView.sliderData = speedData
            break
        }
    }
    
    // MARK: - ACTIONS
    
    @objc func cameraOptionTapped(_ sender: UIButton){
        delegate?.didCameraOptionTapped(with: sender.tag, updateEvent: false)
    }
}
