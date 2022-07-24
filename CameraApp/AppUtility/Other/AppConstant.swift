//
//  AppConstant.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import Foundation
import UIKit

struct AppConstants {
    
    /// Camera Options width  and height
    static let camera_option_Width = 55.0 - 5.0
    static let camera_option_Height = 77.0 - 5.0
    
}

struct windowConstant {
    
    private static let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    
    static var getTopPadding: CGFloat {
        return window?.safeAreaInsets.top ?? 0
    }
    
    static var getBottomPadding: CGFloat {
        return window?.safeAreaInsets.bottom ?? 0
    }
    
}

struct Colors {
    
    static let lightGreen = UIColor.init(red: 135/255, green: 199/255, blue: 66/255, alpha: 1)
    static let skyBlue = UIColor.hexStringToUIColor(hex: "#00BFFF")

}
