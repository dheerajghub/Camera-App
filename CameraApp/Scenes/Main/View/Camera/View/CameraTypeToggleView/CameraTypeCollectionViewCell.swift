//
//  CameraTypeCollectionViewCell.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 25/06/22.
//

import UIKit

class CameraTypeCollectionViewCell: UICollectionViewCell {
    
    // MARK: PROPERTIES -
    
    override var isSelected: Bool {
        didSet {
            typeLabel.textColor = isSelected ? .white : .lightGray.withAlphaComponent(0.6)
        }
    }
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Reels".uppercased()
        label.textAlignment = .center
        label.textColor = .lightGray.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
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
        addSubview(typeLabel)
    }
    
    func setUpConstraints(){
        typeLabel.pin(to: self)
    }
    
}
