//
//  CustomVideoTimerBarView.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 02/07/22.
//

import UIKit

protocol CustomVideoTimerBarActionDelegate {
    func didVideoCompleted()
}

class CustomVideoTimerBarView: UIView {

    // MARK: PROPERTIES -
    
    var timerBarViewHeightConstraint: NSLayoutConstraint?
    var delegate: CustomVideoTimerBarActionDelegate?
    
    let trackLayer = CAShapeLayer()
    var animateFrom = 0.0
    var animateTo = 1.0
    var withDuration = 0.0
    var timer = Timer()
    var totalDuration = 0.0
    var pointerWidth: CGFloat = 3.5
    var speed: Double = 1
    
    var pointerEnds:[Double] = [0]
    lazy var durationPointers:[Double] = [withDuration - 1]
    
    lazy var timerBarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.clipsToBounds = true
        return v
    }()
    
    lazy var timerCounterLabel: UILabel = {
        let v = UILabel()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.text = "0:\(String(format: "%02d", Int(withDuration - 1)))"
        v.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        v.layer.shadowColor = UIColor.black.withAlphaComponent(0.6).cgColor
        v.layer.shadowRadius = 2
        v.layer.shadowOpacity = 1.0
        v.layer.shadowOffset = CGSize(width: 0, height: 0)
        v.layer.masksToBounds = false
        v.isHidden = true
        v.alpha = 0
        
        v.textColor = .white
        return v
    }()
    
    // MARK: MAIN -
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
        setUpLayers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        addSubview(timerBarView)
        addSubview(timerCounterLabel)
    }
    
    func setUpConstraints(){
        NSLayoutConstraint.activate([
            timerBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            timerBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            timerBarView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            
            timerCounterLabel.topAnchor.constraint(equalTo: timerBarView.bottomAnchor, constant: 20),
            timerCounterLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        timerBarViewHeightConstraint = timerBarView.heightAnchor.constraint(equalToConstant: 5)
        timerBarViewHeightConstraint?.isActive = true
    }
    
    func setUpLayers(){
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 0, y: 0))
        linePath.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: 0))
        
        let line = CAShapeLayer()
        line.path = linePath.cgPath
        line.opacity = 1.0
        line.lineWidth = 10
        line.strokeColor = UIColor.black.withAlphaComponent(0.5).cgColor
        line.position = CGPoint(x: 0, y: 5)
        timerBarView.layer.addSublayer(line)
        
        trackLayer.path = linePath.cgPath
        trackLayer.opacity = 1.0
        trackLayer.lineWidth = 10
        trackLayer.strokeColor = Colors.lightGreen.cgColor
        trackLayer.strokeEnd = 0
        trackLayer.position = CGPoint(x: 0, y: 5)
        timerBarView.layer.addSublayer(trackLayer)
    }
    
    func startAnimatingTrackLayer(reload: Bool){
        
        if !reload {
            timer.invalidate()
            self.changeDuration()
            timer = Timer.scheduledTimer(withTimeInterval: (1 * speed), repeats: true) { [weak self] timer in
                self?.changeDuration()
            }
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = animateFrom
            animation.duration = withDuration * speed
            animation.toValue = animateTo
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            trackLayer.add(animation, forKey: "strokeAnimation")
        } else {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.duration = 0.01
            animation.toValue = 0
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            trackLayer.add(animation, forKey: "strokeAnimation")
        }
        
        print("stroke end",trackLayer.strokeEnd)
    }
    
    func stopAnimatingTrackLayer(){
        timer.invalidate()
        if let presentationLayer = trackLayer.presentation() {
            trackLayer.strokeEnd = presentationLayer.strokeEnd
        }
        
        trackLayer.removeAnimation(forKey: "strokeAnimation")
        animateFrom = Double(trackLayer.strokeEnd)
        
        /// Creating border line
        let pointerPosition = UIScreen.main.bounds.width * trackLayer.strokeEnd
        createBorderLayer(at: pointerPosition)
        let strokeEnd = Double(trackLayer.strokeEnd)
        pointerEnds.append(strokeEnd)
        durationPointers.append(withDuration)
    }
    
    func changeDuration(){
        timerCounterLabel.text = "0:\(String(format: "%02d", Int(withDuration - 1)))"
        if withDuration > 0 {
            withDuration -= 1
        }
        if withDuration <= 0 {
            timer.invalidate()
            delegate?.didVideoCompleted()
        }
    }
    
    func createBorderLayer(at x: CGFloat){
        let borderLayer = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 1, y: 0))
        linePath.addLine(to: CGPoint(x: pointerWidth, y: 0))
        borderLayer.path = linePath.cgPath

        borderLayer.opacity = 1.0
        borderLayer.lineWidth = 10
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.position = CGPoint(x: (x - pointerWidth), y: 0)

        trackLayer.addSublayer(borderLayer)
    }
    
    func reloadViews(){
        /// Reloading views
        startAnimatingTrackLayer(reload: true)
        timerCounterLabel.text = "0:\(String(format: "%02d", Int(withDuration - 1)))"
        animateFrom = 0
        trackLayer.sublayers?.removeAll()
        
        durationPointers = [withDuration - 1]
        pointerEnds = [0]
    }
    
    func rewindAnimation(){
        // Take second last pointerEnd
        let pointerCount = pointerEnds.count
        let lastPointer = pointerEnds[pointerCount - 1]
        let secondLastPointer = pointerEnds[pointerCount - 2]
        
        let secondLastDuration = durationPointers[durationPointers.count - 2]
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = lastPointer
        animation.duration = 0.3
        animation.toValue = secondLastPointer
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        trackLayer.add(animation, forKey: "strokeAnimation")
        
        pointerEnds.removeLast()
        durationPointers.removeLast()
        
        animateFrom = secondLastPointer
        withDuration = secondLastDuration
        timerCounterLabel.text = "0:\(String(format: "%02d", Int(withDuration)))"
        
        _ = trackLayer.sublayers?.popLast()
    }
    
    func rewindAnimationAfterTrim(arrayIndexes:Array<Int>){
        
        trackLayer.sublayers?.removeAll()
        
        var newPointersArray:Array<Double> = []
        var newDurationArray:Array<Double> = []
        
        var i = 0
        for index in pointerEnds{
            if(pointerEnds.count > i+1){
                newPointersArray.append(pointerEnds[i+1]-index)
                i = i + 1
            }
        }
        
        var j = 0
        for index in durationPointers{
            if(durationPointers.count > j+1){
                newDurationArray.append(index-durationPointers[j+1])
                j = j + 1
            }
        }
        
        if(newPointersArray.count > 0){
            for index in arrayIndexes{
                if(newPointersArray.count > index){
                    newPointersArray.remove(at: index)
                }
                
                if(newDurationArray.count > index){
                    newDurationArray.remove(at: index)
                }
            }
            
            pointerEnds.removeAll()
            var endValue = 0.0
            pointerEnds.append(endValue)
            for value in newPointersArray{
                endValue = value + endValue
                
                pointerEnds.append(endValue)
                
            }
            
            durationPointers.removeAll()
            var durationValue = 14.0
            for value in newDurationArray{
                if(durationValue > value){
                    durationValue = durationValue - value
                    durationPointers.append(durationValue)
                }
            }
            
            durationPointers.insert(14.0, at: 0)
            
            if(endValue > 0.0){
                trackLayer.strokeStart = CGFloat(0.0)
                trackLayer.strokeEnd = CGFloat(endValue)
                
                var startValue = 0.0
                for newValue in newPointersArray{
                    createBorderLayer(at:UIScreen.main.bounds.width * CGFloat(newValue+startValue))
                    startValue = newValue
                }
                
                animateFrom = endValue
                animateTo = 1.0
                withDuration = durationValue
                timerCounterLabel.text = "0:\(String(format: "%02d", Int(withDuration - 1)))"
                
            }else{
                self.reloadViews()
            }
        }else{
            self.reloadViews()
        }
    }
    
    func updateTheAnimation(duration:Double){
        let newValue = (pointerEnds.last ?? 0.0) + duration*0.07142857143
        pointerEnds.append(newValue)
        durationPointers.append((durationPointers.last ?? 0.0)-duration)
        
        let pointerCount = pointerEnds.count
        let lastPointer = pointerEnds[pointerCount-1]
        let secondLastPointer = pointerEnds[pointerCount - 2]
        
        let lastDuration = durationPointers[durationPointers.count-1]
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = secondLastPointer
        animation.duration = 0.3
        animation.toValue = lastPointer
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        trackLayer.add(animation, forKey: "strokeAnimation")
        
        animateFrom = lastPointer
        withDuration = lastDuration
        timerCounterLabel.text = "0:\(String(format: "%02d", Int(withDuration)))"
        
        createBorderLayer(at:UIScreen.main.bounds.width * CGFloat(newValue))
    }
}
