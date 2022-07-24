//
//  CameraButtonView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 08/06/22.
//

import Foundation
import UIKit

enum CameraButtonState {
    case active
    case inactive
}

protocol CameraButtonViewActionDelegate {
    func didCameraButtonTapped(with state: CameraButtonState)
}

class CameraButtonView: UIView {
    
    // MARK: PROPERTIES -
    
    let circularLayer = CAShapeLayer()
    var cameraButtonState: CameraButtonState = .inactive
    var delegate: CameraButtonViewActionDelegate?
    
    let cameraButtonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
        setUpLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(cameraButtonView)
        addSubview(cameraButton)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            cameraButtonView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cameraButtonView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButtonView.widthAnchor.constraint(equalToConstant: 80),
            cameraButtonView.heightAnchor.constraint(equalToConstant: 80),
            
            cameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 80),
            cameraButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func setUpLayer(){
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 35, startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        circularLayer.strokeColor = UIColor.white.cgColor
        circularLayer.fillColor = UIColor.white.withAlphaComponent(0.7).cgColor
        circularLayer.lineWidth = 8
        circularLayer.path = circularPath.cgPath
        circularLayer.position = CGPoint(x: 40, y: 40)
        
        circularLayer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        circularLayer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        circularLayer.shadowOpacity = 1.0
        circularLayer.shadowRadius = 15.0
        
        cameraButtonView.layer.addSublayer(circularLayer)
    }
    
    func playButtonAnimation( withScale scale: Bool){
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        if scale {
            scaleAnimation.duration = 0.3
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 1.2
            scaleAnimation.fillMode = .forwards
            scaleAnimation.isRemovedOnCompletion = false
            circularLayer.strokeColor = Colors.lightGreen.cgColor
            circularLayer.fillColor = Colors.lightGreen.withAlphaComponent(0.5).cgColor
        } else {
            scaleAnimation.duration = 0.3
            scaleAnimation.fromValue = 1.2
            scaleAnimation.toValue = 1.0
            scaleAnimation.fillMode = .backwards
            scaleAnimation.isRemovedOnCompletion = true
            circularLayer.strokeColor = UIColor.white.cgColor
            circularLayer.fillColor = UIColor.white.withAlphaComponent(0.7).cgColor
        }
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        circularLayer.add(scaleAnimation, forKey: "scale")
        layerLineWidthAnimation(isClosing: false)
    }
    
    func layerLineWidthAnimation(isClosing: Bool){
        let currWidthVal = circularLayer.presentation()?.value(forKeyPath: "lineWidth") ?? 0.0
        let animation = CABasicAnimation(keyPath: "lineWidth")
        if isClosing {
            animation.duration = 0.2
            animation.fromValue = currWidthVal
            animation.toValue = 8
            animation.isRemovedOnCompletion = true
        } else {
            animation.duration = 0.6
            animation.fromValue = 8
            animation.toValue = 15
            animation.repeatCount = .greatestFiniteMagnitude
            animation.isRemovedOnCompletion = false
            animation.autoreverses = true
        }
        
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        circularLayer.add(animation, forKey: "width")
    }
    
    func animateButtonWithState(with state: CameraButtonState) {
        if cameraButtonState == .active {
            cameraButtonState = .inactive
            playButtonAnimation(withScale: false)
            layerLineWidthAnimation(isClosing: true)
        } else {
            cameraButtonState = .active
            playButtonAnimation(withScale: true)
        }
    }
    
    // MARK: - ACTIONS
    
    @objc func cameraButtonTapped(){
        delegate?.didCameraButtonTapped(with: cameraButtonState)
    }
    
}
