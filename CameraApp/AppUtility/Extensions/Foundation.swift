//
//  Foundation.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 05/06/22.
//

import Foundation
import UIKit

extension Collection {

    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
}

extension UIDevice {
    var hasNotch: Bool {
            if #available(iOS 11.0, *) {
                if UIApplication.shared.windows.count == 0 { return false }          // Should never occur, but…
                let top = UIApplication.shared.windows[0].safeAreaInsets.top
                return top > 20          // That seem to be the minimum top when no notch…
            } else {
                // Fallback on earlier versions
                return false
            }
        }
}
