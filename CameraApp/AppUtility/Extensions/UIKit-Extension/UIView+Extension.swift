//
//  UIView+Extension.swift
//  SwiggyClone
//
//  Created by Dheeraj Kumar Sharma on 29/01/22.
//

import UIKit

extension UIView {
    
    func pin(to superView: UIView){
        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
    }
    
    func addBlurrView() {
        let blurrEffect = UIBlurEffect(style: .dark)
        let blurrView = UIVisualEffectView(effect: blurrEffect)
        blurrView.frame = self.bounds
        blurrView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurrView)
    }
    
}
