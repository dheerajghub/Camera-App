//
//  CameraOptions.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import Foundation

enum CameraOptions: Int {
    case flash = 0
    case flip
    case timer
    case speed
}

struct CameraOption {
    let optionName: String
    let optionImage: String
}
