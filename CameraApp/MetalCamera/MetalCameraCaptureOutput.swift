//
//  MetalCameraCaptureOutput.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import AVFoundation
import UIKit

public typealias blockCompletionCapturePhoto = (_ image: UIImage?, _ error: Error?) -> (Void)
public typealias blockCompletionCapturePhotoBuffer = ((_ sampleBuffer: CMSampleBuffer?, _ error: Error?) -> Void)
public typealias blockCompletionCaptureVideo = (_ url: URL?, _ error: NSError?) -> (Void)
public typealias blockCompletionOutputBuffer = (_ sampleBuffer: CMSampleBuffer) -> (Void)
public typealias blockCompletionProgressRecording = (_ duration: Float64) -> (Void)

extension AVCaptureVideoOrientation {
    static func orientationFromUIDeviceOrientation(_ orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }
}

class MetalCameraCaptureOutput: NSObject {
    
    let stillCameraOutput = AVCapturePhotoOutput()
    var movieFileOutput = AVCaptureMovieFileOutput()
    var captureVideoOutput = AVCaptureVideoDataOutput()
    var captureAudioOutput = AVCaptureAudioDataOutput()
    var blockCompletionVideo: blockCompletionCaptureVideo?
    var blockCompletionPhoto: blockCompletionCapturePhoto?
    
    let videoEncoder = MetalCameraVideoEncoder()
    var isRecording = false
    var blockCompletionBuffer: blockCompletionOutputBuffer?
    var blockCompletionProgress: blockCompletionProgressRecording?
    
    func capturePhotoBuffer(settings: AVCapturePhotoSettings, _ blockCompletion: @escaping blockCompletionCapturePhotoBuffer) {
        guard let connectionVideo  = self.stillCameraOutput.connection(with: AVMediaType.video) else {
            blockCompletion(nil, nil)
            return
        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        self.stillCameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func capturePhoto(settings: AVCapturePhotoSettings,currentDevice: AVCaptureDevice? , _ blockCompletion: @escaping blockCompletionCapturePhoto) {
        guard let connectionVideo  = self.stillCameraOutput.connection(with: AVMediaType.video) else {
            blockCompletion(nil, nil)
            return
        }
        self.blockCompletionPhoto = blockCompletion
//        if currentDevice?.position == AVCaptureDevice.Position.front {
//            connectionVideo.isVideoMirrored = true
//        }
        connectionVideo.videoOrientation = AVCaptureVideoOrientation.orientationFromUIDeviceOrientation(UIDevice.current.orientation)
        self.stillCameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func setPressetVideoEncoder(_ videoEncoderPresset: MetalCameraVideoEncoderSettings) {
        self.videoEncoder.presetSettingEncoder = videoEncoderPresset.configuration()
    }
    
    func startRecordVideo(_ blockCompletion: @escaping blockCompletionCaptureVideo, url: URL ,currentDevice: AVCaptureDevice?) {
        if self.isRecording == false {
          //  self.videoEncoder.startWriting(url)
            self.isRecording = true
          
           
            
            movieFileOutput.startRecording(to: url, recordingDelegate: self)
            
        }
        else {
            self.isRecording = false
            self.stopRecordVideo()
        }
        self.blockCompletionVideo = blockCompletion
    }
    
    func stopRecordVideo() {
        self.isRecording = false
       // self.videoEncoder.stopWriting(self.blockCompletionVideo)
        
        if movieFileOutput.isRecording {
         
            movieFileOutput.stopRecording()
        }
    }
    
    func configureCaptureOutput(_ session: AVCaptureSession, sessionQueue: DispatchQueue ,currentDevice: AVCaptureDevice?) {
        if session.canAddOutput(self.captureVideoOutput) {
            session.addOutput(self.captureVideoOutput)
            self.captureVideoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.captureVideoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            guard let connection = captureVideoOutput.connections.first,
                connection.isVideoOrientationSupported else {
                    session.commitConfiguration()
                    return
            }
            connection.videoOrientation = .portrait
        }
        if session.canAddOutput(self.captureAudioOutput) {
            session.addOutput(self.captureAudioOutput)
            self.captureAudioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }
        if session.canAddOutput(self.stillCameraOutput) {
            session.addOutput(self.stillCameraOutput)
        }
        
        
     }
}

extension MetalCameraCaptureOutput: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let error = error {
            self.blockCompletionPhoto?(nil, error)
        }
        else {
            if let sampleBuffer = photoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: nil) {
                let image = UIImage(data: dataImage)
                self.blockCompletionPhoto?(image, nil)
            }
            else {
                self.blockCompletionPhoto?(nil, nil)
            }
        }
    }
}

extension MetalCameraCaptureOutput: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private func progressCurrentBuffer(_ sampleBuffer: CMSampleBuffer) {
        if let block = self.blockCompletionProgress, self.isRecording {
            block(self.videoEncoder.progressCurrentBuffer(sampleBuffer))
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.progressCurrentBuffer(sampleBuffer)
        if let block = self.blockCompletionBuffer {
            block(sampleBuffer)
        }
        if CMSampleBufferDataIsReady(sampleBuffer) == false || self.isRecording == false {
            return
        }
        if captureOutput == self.captureVideoOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: true)
        }
        else if captureOutput == self.captureAudioOutput {
            self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
        }
    }
}

extension MetalCameraCaptureOutput: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("end recording video1 ... \(outputFileURL)")
        print("error : \(String(describing: error))")
        if let blockCompletionVideo = self.blockCompletionVideo {
            blockCompletionVideo(outputFileURL, error as NSError?)
        }
    }
    
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("start recording ...")
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("end recording video ... \(String(describing: outputFileURL))")
        print("error : \(String(describing: error))")
        if let blockCompletionVideo = self.blockCompletionVideo {
            blockCompletionVideo(outputFileURL, error as NSError?)
        }
    }
}


