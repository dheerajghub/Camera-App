//
//  MetalDevice.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import Metal
import CoreGraphics

/// A singleton class containing shared resources
public class MetalDevice {
    public static let shared: MetalDevice = MetalDevice()
    public static var sharedDevice: MTLDevice { return shared.device }
    public static var sharedCommandQueue: MTLCommandQueue { return shared.commandQueue }
    public static var sharedColorSpace: CGColorSpace { return shared.colorSpace }
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    public let colorSpace: CGColorSpace
    
    private init() {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        colorSpace = CGColorSpaceCreateDeviceRGB()
    }
}
