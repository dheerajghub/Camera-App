//
//  SliderData.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 05/06/22.
//

import Foundation

enum SliderType {
    case speed
    case timer
    case duration
}

struct SliderData {
    let type: SliderType
    let names: [String]
    let values: [Float]
    var selectedIndex: Int
}
