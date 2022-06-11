//
//  CountdownTimerView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 08/06/22.
//

import UIKit

import UIKit

class CountDownTimerView: UIView {

    // MARK: - PROPERTIES
    
    var counterFor = 0
    var timer: Timer?
    var callback:(() -> Void)?
    
    let counterLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 100, weight: .heavy)
        label.alpha = 0
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - MAIN
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - FUNTIONS
    
    func setupViews(){
        backgroundColor = .black.withAlphaComponent(0.5)
        addSubview(counterLabel)
    }
    
    func setupConstraints(){
        NSLayoutConstraint.activate([
            counterLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            counterLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            counterLabel.topAnchor.constraint(equalTo: topAnchor),
            counterLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func startTimer(){
        timerAction()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    // MARK: -  ACTIONS
    
    @objc func timerAction(){
//        if counterFor <= 3 {
//            self.counterLabel.textColor = .green.withAlphaComponent(0.8)
//        }
        self.counterLabel.text = "\(counterFor)"
        UIView.animate(withDuration: 0.9, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseIn) {
            self.counterLabel.transform = .init(scaleX: 2, y: 2)
            self.counterLabel.alpha = 1
        } completion: { finished in
            UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut) { [weak self] in
                self?.counterLabel.transform = .identity
                self?.counterLabel.alpha = 0
                if self?.counterFor == 1 {
                    self?.timer?.invalidate()
                    self?.isHidden = true
                    self?.callback!()
                } else {
                    self?.counterFor -= 1
                }
            }
        }

    }

}
