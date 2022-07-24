//
//  CameraTypeToggleView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 25/06/22.
//

import UIKit

protocol CameraTypeActionDelegate {
    func toggleCameraType(to type: CameraTypeState)
}

class CameraTypeToggleView: UIView {

    // MARK: PROPERTIES -
    
    let typesArr = ["Video", "Reels"]
    let cameraType: [CameraTypeState] = [.video , .reel]
    var delegate: CameraTypeActionDelegate?
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.setCollectionViewLayout(layout, animated: false)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.bounces = false
        collectionView.isScrollEnabled = false
        collectionView.register(CameraTypeCollectionViewCell.self, forCellWithReuseIdentifier: "CameraTypeCollectionViewCell")
        return collectionView
    }()
    
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.collectionView.contentInset = UIEdgeInsets(top: 0, left: ((self?.frame.size.width ?? 0) / 2 - 30), bottom: 0, right: ((self?.frame.size.width ?? 0) / 2 - 30))
            self?.collectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            self?.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .centeredHorizontally, animated: false)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(collectionView)
    }
    
    func setUpConstraints(){
        collectionView.pin(to: self)
    }

}

extension CameraTypeToggleView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return typesArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraTypeCollectionViewCell", for: indexPath) as! CameraTypeCollectionViewCell
        cell.typeLabel.text = typesArr[indexPath.row].uppercased()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.toggleCameraType(to: cameraType[indexPath.item])
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
}
