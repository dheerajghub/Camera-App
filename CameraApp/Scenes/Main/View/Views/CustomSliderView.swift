//
//  CustomSliderView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit
import AudioToolbox

protocol CustomSliderActionDelegate {
    func didConfirmValueChangeTapped(with data: SliderData)
}

class CustomSliderView: UIView {

    // MARK: PROPERTIES -
    
    var delegate: CustomSliderActionDelegate?
    var viewModel: CameraViewModel?
    
    var currentPage = 0
    var oldPage = 0
    var newPage = 0
    var slider_value_width = 30.0
    var minimumInterItemSpacing = 10.0
    
    var sliderData: SliderData? {
        didSet {
            guard let sliderData = sliderData else {
                return
            }
            collectionView.reloadData()
            
            let selectedIndex = sliderData.selectedIndex
            let value = sliderData.values[selectedIndex]
            if sliderData.type == .speed {
                valuePreviewView.setTitle("Speed \(value)x", for: .normal)
            } else {
                valuePreviewView.setTitle("Timer \(Int(value))s", for: .normal)
            }
        
            collectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: false)
            
        }
    }
    
    let backGradientView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let sliderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let sliderPointer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.lightGreen
        view.layer.cornerRadius = 2
        return view
    }()
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout.init())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = SnappingCollectionViewLayout()
        layout.scrollDirection = .horizontal
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        collectionView.register(SliderCollectionViewCell.self, forCellWithReuseIdentifier: "SliderCollectionViewCell")
        collectionView.decelerationRate = .fast
        return collectionView
    }()
    
    // MARK: - SLIDER VALUE PREVIEW
    
    let valuePreviewBlurrView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 17.5
        view.layer.masksToBounds = true
        return view
    }()
    
    let valuePreviewView: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Timer 3s", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return button
    }()
    
    //:
    
    // MARK: - CONFIRM BUTTON
    
    lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = Colors.lightGreen
        button.layer.cornerRadius = 25
        button.setImage(UIImage(named: "ic_check")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    //:
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
         [self] in
            let width = collectionView.frame.size.width / 2
            let sliderWidth = slider_value_width / 2
            collectionView.contentInset = UIEdgeInsets(top: 0, left: (width - sliderWidth), bottom: 0, right: (width - sliderWidth))
            valuePreviewBlurrView.addBlurrView()
            backGradientView.setGradient(withColors: [UIColor.black.withAlphaComponent(0.8).cgColor , UIColor.clear.withAlphaComponent(0).cgColor], startPoint: CGPoint(x: 0, y: 1), endPoint: CGPoint(x: 0, y: 0))
            
            self.valuePreviewView.center.y += 20
            self.valuePreviewView.alpha = 0
            self.valuePreviewBlurrView.center.y += 20
            self.valuePreviewBlurrView.alpha = 0
            self.sliderView.center.y += 20
            self.sliderView.alpha = 0
            self.confirmButton.center.y += 20
            self.confirmButton.alpha = 0
        })
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(backGradientView)
        addSubview(valuePreviewBlurrView)
        addSubview(valuePreviewView)
        addSubview(sliderView)
        sliderView.addSubview(collectionView)
        sliderView.addSubview(sliderPointer)
        addSubview(confirmButton)
    }
    
    func setUpConstraints(){
        backGradientView.pin(to: self)
        NSLayoutConstraint.activate([
            valuePreviewBlurrView.topAnchor.constraint(equalTo: valuePreviewView.topAnchor),
            valuePreviewBlurrView.leadingAnchor.constraint(equalTo: valuePreviewView.leadingAnchor),
            valuePreviewBlurrView.trailingAnchor.constraint(equalTo: valuePreviewView.trailingAnchor),
            valuePreviewBlurrView.heightAnchor.constraint(equalToConstant: 35),
            
            valuePreviewView.centerXAnchor.constraint(equalTo: centerXAnchor),
            valuePreviewView.bottomAnchor.constraint(equalTo: sliderView.topAnchor, constant: -25),
            valuePreviewView.heightAnchor.constraint(equalToConstant: 35),
            
            sliderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sliderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sliderView.heightAnchor.constraint(equalToConstant: 70),
            sliderView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -50),
            
                collectionView.heightAnchor.constraint(equalToConstant: 50),
                collectionView.centerYAnchor.constraint(equalTo: sliderView.centerYAnchor),
                collectionView.leadingAnchor.constraint(equalTo: sliderView.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: sliderView.trailingAnchor),
                
                sliderPointer.widthAnchor.constraint(equalToConstant: 4),
                sliderPointer.topAnchor.constraint(equalTo: sliderView.topAnchor),
                sliderPointer.bottomAnchor.constraint(equalTo: sliderView.bottomAnchor),
                sliderPointer.centerXAnchor.constraint(equalTo: sliderView.centerXAnchor),
            
            confirmButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            confirmButton.widthAnchor.constraint(equalToConstant: 90),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = (scrollView.contentOffset.x + (collectionView.frame.size.width / 2))/(slider_value_width + minimumInterItemSpacing)
        let page = abs(Int(position))
        currentPage = page
        newPage = page
        if newPage != oldPage {
            createVibration()
            hinderAnimation()
            oldPage = page
        }
        guard let sliderData = sliderData else {
            return
        }
        let value = sliderData.values[safe: page] ?? 0
        if sliderData.type == .speed {
            viewModel?.speedData.selectedIndex = page
            valuePreviewView.setTitle("Speed \(value)x", for: .normal)
        } else {
            viewModel?.timerData.selectedIndex = page
            valuePreviewView.setTitle("Timer \(Int(value))s", for: .normal)
        }
        
    }
    
    func createVibration(){
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    func hinderAnimation(){
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseInOut) {
            self.valuePreviewView.transform = .init(scaleX: 1.1, y: 1.1)
            self.valuePreviewBlurrView.transform = .init(scaleX: 1.1, y: 1.1)
        } completion: { finished in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.3, options: .curveEaseInOut) {
                self.valuePreviewView.transform = .identity
                self.valuePreviewBlurrView.transform = .identity
            }
        }
    }
    
    func openAnimation(){
        self.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.alpha = 1
            self.valuePreviewView.center.y -= 20
            self.valuePreviewBlurrView.center.y -= 20
            self.valuePreviewView.alpha = 1
            self.valuePreviewBlurrView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.sliderView.center.y -= 20
            self.sliderView.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.confirmButton.center.y -= 20
            self.confirmButton.alpha = 1
        }
    }
    
    func hideAnimation(){
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.valuePreviewView.center.y += 20
            self.valuePreviewBlurrView.center.y += 20
            self.valuePreviewView.alpha = 0
            self.valuePreviewBlurrView.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.sliderView.center.y += 20
            self.sliderView.alpha = 0
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.confirmButton.center.y += 20
            self.confirmButton.alpha = 0
            self.alpha = 0
        } completion: { finished in
            self.isHidden = true
        }

    }
    
    // MARK: - ACTIONS
    
    @objc func confirmButtonTapped(){
        hideAnimation()
        guard let sliderData = sliderData else {
            return
        }
        delegate?.didConfirmValueChangeTapped(with: sliderData)
    }
    
}

extension CustomSliderView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sliderData = sliderData else {
            return Int()
        }
        return sliderData.names.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let sliderData = sliderData else {
            return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCollectionViewCell", for: indexPath) as! SliderCollectionViewCell
        cell.data = sliderData.names[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: slider_value_width, height: slider_value_width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return minimumInterItemSpacing
    }
    
}

class SnappingCollectionViewLayout: UICollectionViewFlowLayout {

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }

        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalOffset = proposedContentOffset.x + collectionView.contentInset.left

        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)

        let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect)

        layoutAttributesArray?.forEach({ (layoutAttributes) in
            let itemOffset = layoutAttributes.frame.origin.x
            if fabsf(Float(itemOffset - horizontalOffset)) < fabsf(Float(offsetAdjustment)) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        })

        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
    
}

class SliderCollectionViewCell: UICollectionViewCell {
    
    // MARK: PROPERTIES -
    
    var data: String? {
        didSet {
            guard let data = data else {
                return
            }
            if data == "•" {
                dotView.isHidden = false
                cellLabel.text = ""
            } else {
                dotView.isHidden = true
                cellLabel.text = data
            }
            
        }
    }
    
    let cellLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "•"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    let dotView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
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
        addSubview(cellLabel)
        addSubview(dotView)
    }
    
    func setUpConstraints(){
        cellLabel.pin(to: self)
        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6),
            dotView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
}
