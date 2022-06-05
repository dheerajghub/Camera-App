//
//  CameraViewModel.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit

protocol CameraViewModelActionDelegate {
    func didCameraOptionTapped(with tag: Int)
}

class CameraViewModel: NSObject {
    
    var delegate: CameraViewModelActionDelegate?
    var isFlashOn = false
    var isFrontCamera = true
    
    let cameraOptions = [
        CameraOption(optionName: "flash", optionImage: "ic_flash_off"),
        CameraOption(optionName: "flip", optionImage: "ic_flip"),
        CameraOption(optionName: "timer", optionImage: "ic_timer"),
        CameraOption(optionName: "speed", optionImage: "ic_speed")
    ]
    
    let timerData = SliderData(type: .timer, names: ["0s","•","•","•","•","5s","•","•","•","•","10s"], values: [0,1,2,3,4,5,6,7,8,9,10])
    let speedData = SliderData(type: .speed, names: ["0x","•","1x","•","2x","•","3x"], values: [0,0.5,1,1.5,2,2.5,3])
    
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
    
    func optionTapped(with type: CameraOptions.RawValue, view: CameraOptionView, sliderView: CustomSliderView) {
        let cameraOption = CameraOptions(rawValue: type) ?? .flash
        switch cameraOption {
        case .flash:
            isFlashOn = !isFlashOn
            view.optionImageView.image = UIImage(named: isFlashOn ? "ic_flash_on" : "ic_flash_off")?.withRenderingMode(.alwaysTemplate)
            view.optionBackView.backgroundColor = isFlashOn ? .white : .clear
            view.optionImageView.tintColor = isFlashOn ? .black : .white
            break
        case .flip:
            break
        case .timer:
            view.optionDetailView.isHidden = false
            view.optionDetailView.backgroundColor = Colors.skyBlue
            view.optionDetailView.setTitle("3s", for: .normal)
            sliderView.valuePreviewView.setTitle("Timer 0s", for: .normal)
            sliderView.openAnimation()
            sliderView.sliderData = timerData
            break
        case .speed:
            view.optionDetailView.isHidden = false
            view.optionDetailView.backgroundColor = Colors.lightGreen
            view.optionDetailView.setTitle("0.5x", for: .normal)
            sliderView.valuePreviewView.setTitle("Speed 0x", for: .normal)
            sliderView.openAnimation()
            sliderView.sliderData = speedData
            break
        }
    }
    
    // MARK: - ACTIONS
    
    @objc func cameraOptionTapped(_ sender: UIButton){
        delegate?.didCameraOptionTapped(with: sender.tag)
    }
}
