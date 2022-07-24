//
//  ReelCameraButtonView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 26/06/22.
//

import UIKit

protocol ReelCameraButtonActionDelegate {
    func didReelCameraButtonTapped(with state: CameraButtonState)
    func didNextButtonTapped()
}

class ReelCameraButtonView: UIView {

    // MARK: PROPERTIES -
    
    let circularLayer = CAShapeLayer()
    var cameraButtonState: CameraButtonState = .inactive
    var delegate: ReelCameraButtonActionDelegate?
    
    let cameraButtonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var cameraButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        button.backgroundColor = .white
        button.setImage(UIImage(named: "ic_reel"), for: .normal)
        return button
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.backgroundColor = .white
        button.setTitle("Next", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.isHidden = true
        button.layer.cornerRadius = 20
        return button
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
        setUpLayer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.cameraButton.layer.cornerRadius = self.cameraButton.frame.size.width / 2
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(cameraButtonView)
        addSubview(cameraButton)
        addSubview(nextButton)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            cameraButtonView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cameraButtonView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButtonView.widthAnchor.constraint(equalToConstant: 80),
            cameraButtonView.heightAnchor.constraint(equalToConstant: 80),
            
            cameraButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: 60),
            cameraButton.heightAnchor.constraint(equalToConstant: 60),
            
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: cameraButtonView.trailingAnchor, constant: 30),
            nextButton.widthAnchor.constraint(equalToConstant: 80),
            nextButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func setUpLayer(){
        let circularPath = UIBezierPath(arcCenter: .zero, radius: 35, startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        circularLayer.strokeColor = UIColor.white.cgColor
        circularLayer.fillColor = UIColor.clear.cgColor
        circularLayer.lineWidth = 5
        circularLayer.path = circularPath.cgPath
        circularLayer.position = CGPoint(x: 40, y: 40)
        
        circularLayer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        circularLayer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        circularLayer.shadowOpacity = 1.0
        circularLayer.shadowRadius = 10.0
        
        cameraButtonView.layer.addSublayer(circularLayer)
    }
    
    func playButtonAnimation( withScale scale: Bool){
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        if scale {
            scaleAnimation.duration = 0.3
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 1.5
            scaleAnimation.fillMode = .forwards
            scaleAnimation.isRemovedOnCompletion = false
            circularLayer.strokeColor = Colors.lightGreen.cgColor
        } else {
            scaleAnimation.duration = 0.3
            scaleAnimation.fromValue = 1.5
            scaleAnimation.toValue = 1.0
            scaleAnimation.fillMode = .backwards
            scaleAnimation.isRemovedOnCompletion = true
            circularLayer.strokeColor = UIColor.white.cgColor
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
            animation.toValue = 5
            animation.isRemovedOnCompletion = true
        } else {
            animation.duration = 0.6
            animation.fromValue = 5
            animation.toValue = 10
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
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.cameraButton.transform = .identity
                self.cameraButton.setImage(UIImage(named: "ic_reel"), for: .normal)
            }
        } else {
            cameraButtonState = .active
            playButtonAnimation(withScale: true)
            UIView.animate(withDuration: 0.3, delay: 0) {
                self.cameraButton.transform = .init(scaleX: 0.8, y: 0.8)
                self.cameraButton.setImage(UIImage(named: "ic_pause"), for: .normal)
            }
        }
    }
    
    
    // MARK: - ACTIONS
    
    @objc func cameraButtonTapped(){
        delegate?.didReelCameraButtonTapped(with: cameraButtonState)
    }
    
    @objc func nextButtonTapped(){
        delegate?.didNextButtonTapped()
    }

}
