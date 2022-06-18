//
//  CameraViewController+CameraConfig.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import UIKit
import AVFoundation

extension CameraViewController {
    
    func checkPermissions() {
        if checkCameraAccess() && checkMicrophoneAccess() {
            setUpCamera()
            DispatchQueue.main.async { [weak self] in
                self?.permissionView.isHidden = true
            }
        } else if checkCameraAccess() {
            DispatchQueue.main.async { [weak self] in
                let cameraPermissionButtonView = self?.permissionView.cameraPermissionView
                self?.permissionView.permissionStackView.removeArrangedSubview(cameraPermissionButtonView!)
                cameraPermissionButtonView?.removeFromSuperview()
            }
        } else if checkMicrophoneAccess() {
            DispatchQueue.main.async { [weak self] in
                let micPermissionButtonView = self?.permissionView.micPermissionView
                self?.permissionView.permissionStackView.removeArrangedSubview(micPermissionButtonView!)
                micPermissionButtonView?.removeFromSuperview()
            }
        } else {
            // Enable Both
        }
    }
    
    func setUpCamera(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.appDelegate.metalView = MetalView(frame: CGRect(x: 0, y: 0, width: self.cameraPreviewView.bounds.width, height:self.cameraPreviewView.bounds.height))
            self.cameraPreviewView.addSubview(self.appDelegate.metalView)
            self.cameraPreviewView.bringSubviewToFront(self.appDelegate.metalView)
            if self.appDelegate.camera != nil {
                self.appDelegate.camera.add(consumer: self.appDelegate.metalView)
            } else {
                self.appDelegate.setupCamera()
                self.setUpCamera()
            }
        }
    }
    
    func checkCameraAccess() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            print("Denied, request permission from settings")
            presentCameraSettings()
            return false
            
        case .restricted:
            print("Restricted, device owner must approve")
            return false
        case .authorized:
            print("Authorized, proceed")
            return true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                                            { (authorized) in
                                                if(!authorized){
                                                    abort()
                                                }
                                            })
            return false

        @unknown default:
            return false
        }
    }
    
    func presentCameraSettings() {
        let alertController = UIAlertController(title: "Error",
                                                message: "Camera access is denied",
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    // Handle
                })
            }
        })
        
        present(alertController, animated: true)
    }
    
    func checkMicrophoneAccess() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.undetermined:
            return false
        case AVAudioSession.RecordPermission.denied:
            let alert = UIAlertController(title: "Error", message: "Please allow microphone usage from settings", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Open settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        case AVAudioSession.RecordPermission.granted:
            return true
        @unknown default:
            return false
        }
    }
    
    func enableCamera(){
        AVCaptureDevice.requestAccess(for: .video) { success in
            if success {
                if(self.appDelegate.camera == nil){
                    self.appDelegate.setupCamera()
                }
                self.checkPermissions()
            } else {
                print("Permission denied")
            }
        }
    }
    
    func enableMic(){
        AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
            if granted {
                
                if(self.appDelegate.camera == nil){
                    self.appDelegate.setupCamera()
                }
                
                self.checkPermissions()
            } else {
                print("Permission denied")
            }
        })
    }
    
    func flipCamera(){
        if(appDelegate.camera == nil){
            return
        }
        appDelegate.camera.switchCameraPosition()
    }
    
    func startRecordingVideo(){
        if(appDelegate.camera == nil){
            return
        }
        if let url = MetalCameraFileManager.temporaryPath("\(arc4random()).mp4") {
            appDelegate.videoWriter.url = url
            appDelegate.videoWriter.start()
        }
    }
    
    func finishAndProcessTheVideo(){
        appDelegate.videoWriter.finish { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                let speed = self.viewModel.currentSpeedScale
                
                /// Generating a video asset with changin a speed video as per  selection
                let asset = AudioVideoManager.shared.changeVideoSpeed(videoUrl: self.appDelegate.videoWriter.url, videoSpeed: speed,audioSpeed: speed)
                
                /// Assigning processed asset to viewModel's variable
                self.viewModel.processVideoAsset = asset
                
                let VC = CameraPreviewViewController()
                VC.videoAsset = asset
                VC.modalPresentationStyle = .fullScreen
                VC.modalTransitionStyle = .crossDissolve
                self.present(VC, animated: true)
            }
        }
    }
    
    
    
}
