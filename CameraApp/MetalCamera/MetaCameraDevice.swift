//
//  MetaCameraDevice.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import UIKit
import AVFoundation

public enum MetalCameraFocus {
    case locked
    case autoFocus
    case continuousAutoFocus
    
    func foundationFocus() -> AVCaptureDevice.FocusMode {
        switch self {
        case .locked: return AVCaptureDevice.FocusMode.locked
        case .autoFocus: return AVCaptureDevice.FocusMode.autoFocus
        case .continuousAutoFocus: return AVCaptureDevice.FocusMode.continuousAutoFocus
        }
    }
    
    public func description() -> String {
        switch self {
        case .locked: return "Locked"
        case .autoFocus: return "AutoFocus"
        case .continuousAutoFocus: return "ContinuousAutoFocus"
        }
    }
    
    public static func availableFocus() -> [MetalCameraFocus] {
        return [
            .locked,
            .autoFocus,
            .continuousAutoFocus
        ]
    }
}


class MetalCameraDevice {
    private var backCameraDevice: AVCaptureDevice!
    private var frontCameraDevice: AVCaptureDevice!
    var micCameraDevice: AVCaptureDevice!
    var currentDevice: AVCaptureDevice?
    var currentPosition: AVCaptureDevice.Position = .unspecified
    var zoom: CGFloat = 1.0
    public var maxZoomScale = CGFloat.greatestFiniteMagnitude
    func changeCameraFocusMode(_ focusMode: MetalCameraFocus) {
        if let currentDevice = self.currentDevice {
            do {
                try currentDevice.lockForConfiguration()
                if currentDevice.isFocusModeSupported(focusMode.foundationFocus()) {
                    currentDevice.focusMode = focusMode.foundationFocus()
                }
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[MetalCamera] error, impossible to lock configuration device")
            }
        }
    }
    
    func changeCurrentZoomFactor(_ newFactor: CGFloat) -> CGFloat {
      
        if let currentDevice = self.currentDevice {
            do {
                try currentDevice.lockForConfiguration()
                zoom = min(maxZoomScale, max(1.0, min(newFactor, currentDevice.activeFormat.videoMaxZoomFactor)))
                currentDevice.videoZoomFactor = zoom
                currentDevice.unlockForConfiguration()
            }
            catch {
                zoom = -1.0
                fatalError("[MetalCamera] error, impossible to lock configuration device")
            }
        }
        
        return zoom
    }
    
    func changeCurrentDevice(_ position: AVCaptureDevice.Position) {
        self.currentPosition = position
        switch position {
        case .back: self.currentDevice = self.backCameraDevice
        case .front: self.currentDevice = self.frontCameraDevice
        case .unspecified: self.currentDevice = nil
        @unknown default:
            self.currentDevice = nil
        }
    }
    private func configureDeviceCamera() {
        self.backCameraDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera,AVCaptureDevice.DeviceType.builtInDualWideCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera, AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back).devices.first
        
        self.frontCameraDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInDualCamera, AVCaptureDevice.DeviceType.builtInTelephotoCamera, AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front).devices.first
    }
    
    private func configureDeviceMic() {
        self.micCameraDevice = AVCaptureDevice.default(for: .audio )
    }
    
    init() {
        self.configureDeviceCamera()
        self.configureDeviceMic()
        self.changeCurrentDevice(.front)
    }
}
