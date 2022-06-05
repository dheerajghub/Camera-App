//
//  CameraOptionView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit

class CameraOptionView: UIView {

    // MARK: PROPERTIES -
    
    let optionBlurrView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = (AppConstants.camera_option_Width - 10) / 2
        view.layer.masksToBounds = true
        return view
    }()
    
    let optionBackView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = (AppConstants.camera_option_Width - 10) / 2
        return view
    }()
    
    let optionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    let optionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 11, weight: .heavy)
        
        
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 1.0
        label.layer.shadowOffset = CGSize(width: 0, height: 2)
        label.layer.masksToBounds = false
        
        return label
    }()
    
    let optionActionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - OPTION DETAIL LABEL
    
    let optionDetailView: UIButton = {
        let view = UIButton()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.lightGreen
        view.layer.cornerRadius = ((AppConstants.camera_option_Width - 10) * 0.4) / 2
        view.setTitle("0.5x", for: .normal)
        view.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
        view.setTitleColor(.white, for: .normal)
        view.isHidden = true
        view.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        return view
    }()
    
    //:
    
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
        addSubview(optionBlurrView)
        addSubview(optionBackView)
        optionBackView.addSubview(optionImageView)
        
        optionBackView.addSubview(optionDetailView)
//        optionDetailView.addSubview(optionDetailLabel)
        
        addSubview(optionLabel)
        addSubview(optionActionButton)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [self] in
            optionBlurrView.addBlurrView()
        })
        
    }
    
    func setUpConstraints(){
        optionActionButton.pin(to: self)
        NSLayoutConstraint.activate([
            
            optionBlurrView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            optionBlurrView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            optionBlurrView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            optionBlurrView.heightAnchor.constraint(equalToConstant: (AppConstants.camera_option_Width - 10)),
            
            optionBackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            optionBackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            optionBackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            optionBackView.heightAnchor.constraint(equalToConstant: (AppConstants.camera_option_Width - 10)),
            
            optionDetailView.centerXAnchor.constraint(equalTo: optionBackView.centerXAnchor),
            optionDetailView.bottomAnchor.constraint(equalTo: optionBackView.bottomAnchor, constant: 10),
            optionDetailView.heightAnchor.constraint(equalToConstant: (AppConstants.camera_option_Width - 10) * 0.4),
//            optionDetailView.widthAnchor.constraint(equalToConstant: (AppConstants.camera_option_Width - 10) * 0.4),
            
            optionLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            optionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3),
            
            optionImageView.leadingAnchor.constraint(equalTo: optionBackView.leadingAnchor, constant: 10),
            optionImageView.trailingAnchor.constraint(equalTo: optionBackView.trailingAnchor, constant: -10),
            optionImageView.topAnchor.constraint(equalTo: optionBackView.topAnchor, constant: 10),
            optionImageView.bottomAnchor.constraint(equalTo: optionBackView.bottomAnchor, constant: -10)
        ])
    }
    
    func tapInteraction(){
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut) {
            self.optionImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.3, options: .curveEaseInOut) {
                self.optionImageView.transform = .identity
            }
        }
    }

}
