//
//  MetalCameraDeviceInput.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import UIKit
import AVFoundation

public enum MetalCameraDeviceInputErrorType: Error {
    case unableToAddCamera
    case unableToAddMic
}


class MetalCameraDeviceInput {
     var cameraDeviceInput: AVCaptureDeviceInput?
    private var micDeviceInput: AVCaptureDeviceInput?
    
    func configureInputCamera(_ session: AVCaptureSession, device: AVCaptureDevice) throws {
        session.beginConfiguration()
        let possibleCameraInput: AnyObject? = try AVCaptureDeviceInput(device: device)
        if let cameraInput = possibleCameraInput as? AVCaptureDeviceInput {
            if let currentDeviceInput = self.cameraDeviceInput {
                session.removeInput(currentDeviceInput)
            }
            self.cameraDeviceInput = cameraInput
            if session.canAddInput(self.cameraDeviceInput!) {
                session.addInput(self.cameraDeviceInput!)
            }
            else {
                throw MetalCameraDeviceInputErrorType.unableToAddCamera
            }
        }
        session.commitConfiguration()
    }
    
    func configureInputMic(_ session: AVCaptureSession, device: AVCaptureDevice) throws {
        if self.micDeviceInput != nil {
            return
        }
        try self.micDeviceInput = AVCaptureDeviceInput(device: device)
        if session.canAddInput(self.micDeviceInput!) {
            session.addInput(self.micDeviceInput!)
        }
        else {
            throw MetalCameraDeviceInputErrorType.unableToAddMic
        }
    }
}
