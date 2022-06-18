//
//  PlayerSliderView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 18/06/22.
//

import UIKit

protocol PlayerSliderActionDelegate {
    func didScrub(sliderValue: Double)
}

class PlayerSliderView: UIView {

    // MARK: PROPERTIES -
    
    var delegate: PlayerSliderActionDelegate?
    
    let startCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
    lazy var playerSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = Colors.lightGreen
        slider.maximumTrackTintColor = .white.withAlphaComponent(0.5)
        slider.addTarget(self, action: #selector(playerScrub), for: .valueChanged)
        slider.setThumbImage(UIImage(named: "ic_thumb"), for: .normal)
        return slider
    }()
    
    let endCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:29"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(startCountLabel)
        addSubview(playerSlider)
        addSubview(endCountLabel)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            startCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            startCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            startCountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            
            endCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            endCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            endCountLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
            
            playerSlider.leadingAnchor.constraint(equalTo: startCountLabel.trailingAnchor, constant: 10),
            playerSlider.trailingAnchor.constraint(equalTo: endCountLabel.leadingAnchor, constant: -10),
            playerSlider.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - ACTIONS
    
    @objc func playerScrub() {
        delegate?.didScrub(sliderValue: Double(playerSlider.value))
    }

}
