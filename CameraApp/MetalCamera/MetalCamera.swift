//
//  MetalCamera.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import Foundation
import AVFoundation
import UIKit
import Photos

public enum MetalCameraSessionPreset {
    case photo
    case high
    case medium
    case low
    case res352x288
    case res640x480
    case res1280x720
    case res1920x1080
    case res3840x2160
    case frame960x540
    case frame1280x720
    case inputPriority
    
    public func foundationPreset() -> String {
        switch self {
        case .photo: return AVCaptureSession.Preset.photo.rawValue
        case .high: return AVCaptureSession.Preset.high.rawValue
        case .medium: return AVCaptureSession.Preset.medium.rawValue
        case .low: return AVCaptureSession.Preset.low.rawValue
        case .res352x288: return AVCaptureSession.Preset.cif352x288.rawValue
        case .res640x480: return AVCaptureSession.Preset.vga640x480.rawValue
        case .res1280x720: return AVCaptureSession.Preset.hd1280x720.rawValue
        case .res1920x1080: return AVCaptureSession.Preset.hd1920x1080.rawValue
        case .res3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSession.Preset.hd4K3840x2160.rawValue
            }
            else {
                return AVCaptureSession.Preset.photo.rawValue
            }
        case .frame960x540: return AVCaptureSession.Preset.iFrame960x540.rawValue
        case .frame1280x720: return AVCaptureSession.Preset.iFrame1280x720.rawValue
        default: return AVCaptureSession.Preset.photo.rawValue
        }
    }
    
    public static func availablePresset() -> [MetalCameraSessionPreset] {
        return [
            .photo,
            .high,
            .medium,
            .low,
            .res352x288,
            .res640x480,
            .res1280x720,
            .res1920x1080,
            .res3840x2160,
            .frame960x540,
            .frame1280x720,
            .inputPriority
        ]
    }
}

/// Camera photo delegate defines handling taking photo result behaviors
public protocol MetalCameraPhotoDelegate: AnyObject {
    /// Called when camera did take a photo and get Metal texture
    ///
    /// - Parameters:
    ///   - camera: camera to use
    ///   - texture: Metal texture of the original photo which is not filtered
    func camera(_ camera: MetalCamera, didOutput texture: MTLTexture)
    
    /// Called when camera fail taking a photo
    ///
    /// - Parameters:
    ///   - camera: camera to use
    ///   - error: error for taking the photo
    func camera(_ camera: MetalCamera, didFail error: Error)
    
}

public protocol MetalCameraMetadataObjectDelegate: AnyObject {
    /// Called when camera did get metadata objects
    ///
    /// - Parameters:
    ///   - camera: camera to use
    ///   - metadataObjects: metadata objects
    func camera(_ camera: MetalCamera, didOutput metadataObjects: [AVMetadataObject])
}

let metalCameraSessionQueueIdentifier = "com.MetalCamera.capturesession"

public class MetalCamera: NSObject {
    
    
    var session = AVCaptureSession()
    var cameraDevice = MetalCameraDevice()
    var cameraInput = MetalCameraDeviceInput()
    var cameraOutput = MetalCameraCaptureOutput()
    var sessionQueue: DispatchQueue = DispatchQueue(label: metalCameraSessionQueueIdentifier)
    
    
    public var captureDevice: AVCaptureDevice? {
        get {
            return cameraDevice.currentDevice
        }
    }
    
    public var currentDevice: AVCaptureDevice.Position {
        get {
            return self.cameraDevice.currentPosition
        }
        set {
            self.changeCurrentDevice(newValue)
        }
    }
    
    public var isRecording: Bool {
        get {
            return self.cameraOutput.isRecording
        }
    }
    
    private var _torchMode: AVCaptureDevice.TorchMode = .off
    public var torchMode: AVCaptureDevice.TorchMode! {
        get {
            return _torchMode
        }
        set {
            _torchMode = newValue
            configureTorch(newValue)
        }
    }
    
    private var _flashMode: AVCaptureDevice.FlashMode = .off
    public var flashMode: AVCaptureDevice.FlashMode! {
        get {
            
            lock.wait()
            let f = _flashMode
            lock.signal()
            return f
           
        }
        set {
            lock.wait()
            _flashMode = newValue
            lock.signal()
        }
    }
    
    /// Image consumers
    public var consumers: [MetalImageConsumer] {
        lock.wait()
        let c = _consumers
        lock.signal()
        return c
    }
    private var _consumers: [MetalImageConsumer]
    
    /// A block to call before processing each video sample buffer
    public var preprocessVideo: ((CMSampleBuffer) -> Void)? {
        get {
            lock.wait()
            let p = _preprocessVideo
            lock.signal()
            return p
        }
        set {
            lock.wait()
            _preprocessVideo = newValue
            lock.signal()
        }
    }
    
    private var _preprocessVideo: ((CMSampleBuffer) -> Void)?
    
    
    /// A block to call before transmiting texture to image consumers
    public var willTransmitTexture: ((MTLTexture, CMTime) -> Void)? {
        get {
            lock.wait()
            let w = _willTransmitTexture
            lock.signal()
            return w
        }
        set {
            lock.wait()
            _willTransmitTexture = newValue
            lock.signal()
        }
    }
    
    private var _willTransmitTexture: ((MTLTexture, CMTime) -> Void)?
    
    /// Camera position
    public var position: AVCaptureDevice.Position { return camera.position  }
    
    
    /// Whether to run benchmark or not.
    /// Running benchmark records frame duration.
    /// False by default.
    public var benchmark: Bool {
        get {
            lock.wait()
            let b = _benchmark
            lock.signal()
            return b
        }
        set {
            lock.wait()
            _benchmark = newValue
            lock.signal()
        }
    }
    private var _benchmark: Bool
    
    /// Average frame duration, or 0 if not valid value.
    /// To get valid value, set `benchmark` to true.
    public var averageFrameDuration: Double {
        lock.wait()
        let d = capturedFrameCount > ignoreInitialFrameCount ? totalCaptureFrameTime / Double(capturedFrameCount - ignoreInitialFrameCount) : 0
        lock.signal()
        return d
    }
    
    private var capturedFrameCount: Int
    private var totalCaptureFrameTime: Double
    private let ignoreInitialFrameCount: Int
    
    private let lock: DispatchSemaphore
    
    private var camera: AVCaptureDevice!
    private var videoInput: AVCaptureDeviceInput!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var videoOutputQueue: DispatchQueue!
    
    private let multitpleSessions: Bool
    private var audioSession: AVCaptureSession!
    private var audioInput: AVCaptureDeviceInput!
    private var audioOutput: AVCaptureAudioDataOutput!
    private var audioOutputQueue: DispatchQueue!
    
    /// Audio consumer processing audio sample buffer.
    /// Set this property to nil (default value) if not recording audio.
    /// Set this property to a given audio consumer if recording audio.
    public var audioConsumer: MetalAudioConsumer? {
        get {
            lock.wait()
            let a = _audioConsumer
            lock.signal()
            return a
        }
        set {
            lock.wait()
            _audioConsumer = newValue
            if newValue != nil {
                if !addAudioInputAndOutput() { _audioConsumer = nil }
            } else {
                removeAudioInputAndOutput()
            }
            lock.signal()
        }
    }
    private var _audioConsumer: MetalAudioConsumer?
    
    private var photoOutput: AVCapturePhotoOutput!
    
    /// Whether can take photo or not.
    /// Set this property to true before calling `takePhoto()` method.
    public var canTakePhoto: Bool {
        get {
            lock.wait()
            let c = _canTakePhoto
            lock.signal()
            return c
        }
        set {
            lock.wait()
            _canTakePhoto = newValue
            if newValue {
                if !addPhotoOutput() { _canTakePhoto = false }
            } else {
                removePhotoOutput()
            }
            lock.signal()
        }
    }
    
    
    private var _canTakePhoto: Bool
    
    /// Camera photo delegate handling taking photo result.
    /// To take photo, this property should not be nil.
    public weak var photoDelegate: MetalCameraPhotoDelegate? {
        get {
            lock.wait()
            let p = _photoDelegate
            lock.signal()
            return p
        }
        set {
            lock.wait()
            _photoDelegate = newValue
            lock.signal()
        }
    }
    
    private weak var _photoDelegate: MetalCameraPhotoDelegate?
    
    private var _needPhoto: Bool
    
    private var _capturePhotoCompletion: MetalFilterCompletion?
    
    private var _blockCompletionPhoto: blockCompletionCapturePhoto?
    
    private var metadataOutput: AVCaptureMetadataOutput!
    private var metadataOutputQueue: DispatchQueue!
    
    public weak var metadataObjectDelegate: MetalCameraMetadataObjectDelegate? {
        get {
            lock.wait()
            let m = _metadataObjectDelegate
            lock.signal()
            return m
        }
        set {
            lock.wait()
            _metadataObjectDelegate = newValue
            lock.signal()
        }
    }
    private weak var _metadataObjectDelegate: MetalCameraMetadataObjectDelegate?
    
    /// When this property is false, received video/audio sample buffer will not be processed
    public var isPaused: Bool {
        get {
            lock.wait()
            let p = _isPaused
            lock.signal()
            return p
        }
        set {
            lock.wait()
            _isPaused = newValue
            lock.signal()
        }
    }
    private var _isPaused: Bool
    
    private var textureCache: CVMetalTextureCache!
    
    /// Creates a camera
    /// - Parameters:
    ///   - sessionPreset: a constant value indicating the quality level or bit rate of the output
    ///   - position: camera position
    ///   - multitpleSessions: whether to use independent video session and audio session (false by default). Switching camera position while recording leads to the video and audio out of sync.
    /// Set true if we allow the user to switch camera position while recording.
    
    public init?(
        sessionPreset: AVCaptureSession.Preset = .high,
        position: AVCaptureDevice.Position = .back,
        multitpleSessions: Bool = true
    ) {
        _consumers = []
        _canTakePhoto = false
        _needPhoto = false
        _isPaused = false
        _benchmark = false
        capturedFrameCount = 0
        totalCaptureFrameTime = 0
        ignoreInitialFrameCount = 5
        self.multitpleSessions = multitpleSessions
        lock = DispatchSemaphore(value: 1)
        
        super.init()
        
        session.sessionPreset = sessionPreset
        self.configureInputDevice()
        self.configureOutputDevice()
        session.commitConfiguration()
        
        #if !targetEnvironment(simulator)
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, MetalDevice.sharedDevice, nil, &textureCache) != kCVReturnSuccess ||
            textureCache == nil {
            return nil
        }
        #endif
    }
    
    //MARK: Device I/O configuration
    
    private func configureInputDevice() {
        do {
            if let currentDevice = self.cameraDevice.currentDevice {
                camera = currentDevice
               
                try self.cameraInput.configureInputCamera(self.session, device: currentDevice)
                videoInput = self.cameraInput.cameraDeviceInput
            }
            if let micDevice = self.cameraDevice.micCameraDevice {
                try self.cameraInput.configureInputMic(self.session, device: micDevice)
            }
        }
        catch MetalCameraDeviceInputErrorType.unableToAddCamera {
            fatalError("[MetalCamera] unable to add camera as InputDevice")
        }
        catch MetalCameraDeviceInputErrorType.unableToAddMic {
            fatalError("[MetalCamera] unable to add mic as InputDevice")
        }
        catch {
            fatalError("[MetalCamera] error initInputDevice")
        }
    }
    
    
    private func configureOutputDevice() {
       // self.cameraOutput.configureCaptureOutput(self.session, sessionQueue: self.sessionQueue , currentDevice:self.cameraDevice.currentDevice)
        let videoDataOutput = AVCaptureVideoDataOutput()
        cameraOutput.movieFileOutput.movieFragmentInterval = CMTime.invalid
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
     //   videoOutputQueue = DispatchQueue(label: "com.Kaibo.BBMetalImage.Camera.videoOutput")
        videoDataOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if !session.canAddOutput(videoDataOutput) {
            session.commitConfiguration()
         //   return nil
        }
        session.addOutput(videoDataOutput)
        videoOutput = videoDataOutput

        guard let connection = videoDataOutput.connections.first,
            connection.isVideoOrientationSupported else {
                session.commitConfiguration()
                return
        }
        connection.videoOrientation = .portrait
    }
    
    
    public func switchCurrentDevice() {
        if self.isRecording == false {
            self.changeCurrentDevice((self.cameraDevice.currentPosition == .back) ? .front : .back)
        }
    }
    
    public func changeCurrentDevice(_ position: AVCaptureDevice.Position) {
        self.cameraDevice.changeCurrentDevice(position)
        self.configureInputDevice()
    }
    
    private func configureTorch(_ mode: AVCaptureDevice.TorchMode) {
      
        
        if let currentDevice = self.camera, currentDevice.isTorchAvailable && currentDevice.torchMode != mode {
            do {
                try currentDevice.lockForConfiguration()
                currentDevice.torchMode = mode
                currentDevice.unlockForConfiguration()
            }
            catch {
                fatalError("[MetalEngine] error lock configuration device")
            }
        }
    }
    
    private func configureFlash(_ mode: AVCaptureDevice.FlashMode) {
 
                
    }
    

    
    @discardableResult
    private func addAudioInputAndOutput() -> Bool {
        if audioOutput != nil { return true }
        
        var session: AVCaptureSession = self.session
        if multitpleSessions {
            session = AVCaptureSession()
            audioSession = session
        }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        guard let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
            let input = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(input) else {
                print("Can not add audio input")
                return false
        }
        session.addInput(input)
        audioInput = input
        
        let output = AVCaptureAudioDataOutput()
        let outputQueue = DispatchQueue(label: "B.Social.PhotoChallenge.Camera.audioOutput")
        output.setSampleBufferDelegate(self, queue: outputQueue)
        guard session.canAddOutput(output) else {
            _removeAudioInputAndOutput()
            print("Can not add audio output")
            return false
        }
        session.addOutput(output)
        audioOutput = output
        audioOutputQueue = outputQueue
        
        return true
    }
    
    private func removeAudioInputAndOutput() {
        session.beginConfiguration()
        _removeAudioInputAndOutput()
        session.commitConfiguration()
    }
    
    private func _removeAudioInputAndOutput() {
        let session: AVCaptureSession = multitpleSessions ? audioSession : self.session
        if let input = audioInput {
            session.removeInput(input)
            audioInput = nil
        }
        if let output = audioOutput {
            session.removeOutput(output)
            audioOutput = nil
        }
        if audioOutputQueue != nil {
            audioOutputQueue = nil
        }
        if audioSession != nil {
            audioSession = nil
        }
    }
    
    
    @discardableResult
    private func addPhotoOutput() -> Bool {
        if photoOutput != nil { return true }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        let output = AVCapturePhotoOutput()
        if !session.canAddOutput(output) {
            print("Can not add photo output")
            return false
        }
        session.addOutput(output)
        photoOutput = output
        
        return true
    }
    
    private func removePhotoOutput() {
        session.beginConfiguration()
        if let output = photoOutput { session.removeOutput(output) }
        session.commitConfiguration()
    }
    
    @discardableResult
    public func addMetadataOutput(with types: [AVMetadataObject.ObjectType]) -> Bool {
        var result = false
        
        lock.wait()
        
        if metadataOutput != nil {
            lock.signal()
            return result
        }
        
        session.beginConfiguration()
        
        let output = AVCaptureMetadataOutput()
        let outputQueue = DispatchQueue(label: "B.Social.PhotoChallenge.metadataOutput")
        output.setMetadataObjectsDelegate(self, queue: outputQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            let validTypes = types.filter { output.availableMetadataObjectTypes.contains($0) }
            output.metadataObjectTypes = validTypes
            metadataOutput = output
            metadataOutputQueue = outputQueue
            result = true
        }
        
        session.commitConfiguration()
        lock.signal()
        return result
    }
    
    public func removeMetadataOutput() {
        lock.wait()
        
        if metadataOutput == nil {
            lock.signal()
            return
        }
        
        session.beginConfiguration()
        
        session.removeOutput(metadataOutput)
        metadataOutput = nil
        metadataOutputQueue = nil
        
        session.commitConfiguration()
        lock.signal()
    }
    
    /// Captures frame texture as a photo.
    /// Get original frame texture in the completion closure.
    /// To get filtered texture, use `addCompletedHandler(_:)` method of `BBMetalBaseFilter`, check whether the filtered texture is camera photo.
    /// This method is much faster than `takePhoto()` method.
    /// - Parameter completion: a closure to call after capturing. If success, get original frame texture. If failure, get error.
    public func capturePhoto(completion: MetalFilterCompletion? = nil) {
        lock.wait()
        _needPhoto = true
        _capturePhotoCompletion = completion
        lock.signal()
    }
    
    
    /// Takes a photo.
    /// Before calling this method, set `canTakePhoto` property to true and `photoDelegate` property to nonnull.
    /// Get original frame texture in `camera(_:didOutput:)` method of `BBMetalCameraPhotoDelegate`.
    /// To get filtered texture, use `capturePhoto(completion:)` method, or create new filter to process the original frame texture.
    public func takePhoto() {
        lock.wait()
        if let output = photoOutput,
            _photoDelegate != nil {
            let currentSettings = getSettings(camera: self.cameraDevice.currentDevice, flashMode: self.flashMode)
            output.capturePhoto(with: currentSettings, delegate: self)
        }
        lock.signal()
    }
    
    
    func capturePhoto(_ blockCompletion: @escaping blockCompletionCapturePhoto) {
        
    //    lock.wait()
        
        if let output = photoOutput {
            _blockCompletionPhoto = blockCompletion
            let currentSettings = getSettings(camera: self.cameraDevice.currentDevice, flashMode: self.flashMode)
            output.capturePhoto(with: currentSettings, delegate: self)
        }
        
       // lock.signal()
        
     
        
    }
    
    func getSettings(camera: AVCaptureDevice?, flashMode: AVCaptureDevice.FlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA])

        if ((camera?.hasFlash) != nil) {
            switch flashMode {
               case .auto: settings.flashMode = .auto
               case .on: settings.flashMode = .on
               default: settings.flashMode = .off
            }
        }
        return settings
    }
    
    /// Switches camera position (back to front, or front to back)
    ///
    /// - Returns: true if succeed, or false if fail
    @discardableResult
    public func switchCameraPosition() -> Bool {
        lock.wait()
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
            lock.signal()
        }
        
        var position: AVCaptureDevice.Position = .back
        if camera.position == .back { position = .front }
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return false }
        
        session.removeInput(videoInput)
        
        guard session.canAddInput(videoDeviceInput) else {
            session.addInput(videoInput)
            return false
        }
        session.addInput(videoDeviceInput)
        camera = videoDevice
        videoInput = videoDeviceInput
        
        guard let connection = videoOutput.connections.first,
            connection.isVideoOrientationSupported else { return false }
        connection.videoOrientation = .portrait
        
        return true
    }
    
    /// Sets camera frame rate
    ///
    /// - Parameter frameRate: camera frame rate
    /// - Returns: true if succeed, or false if fail
    @discardableResult
    public func setFrameRate(_ frameRate: Float64) -> Bool {
        var success = false
        lock.wait()
        do {
            try camera.lockForConfiguration()
            var targetFormat: AVCaptureDevice.Format?
            let dimensions = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
            for format in camera.formats {
                let newDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if dimensions.width == newDimensions.width,
                    dimensions.height == newDimensions.height {
                    for range in format.videoSupportedFrameRateRanges {
                        if range.maxFrameRate >= frameRate,
                            range.minFrameRate <= frameRate {
                            targetFormat = format
                            break
                        }
                    }
                    if targetFormat != nil { break }
                }
            }
            if let format = targetFormat {
                camera.activeFormat = format
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                success = true
            } else {
                print("Can not find valid format for camera frame rate \(frameRate)")
            }
            camera.unlockForConfiguration()
        } catch {
            print("Error for camera lockForConfiguration: \(error)")
        }
        lock.signal()
        return success
    }
    
    /// Configures camera.
    /// Configure camera in the block, without calling `lockForConfiguration` and `unlockForConfiguration` methods.
    ///
    /// - Parameter block: closure configuring camera
    public func configureCamera(_ block: (AVCaptureDevice) -> Void) {
        lock.wait()
        do {
            try camera.lockForConfiguration()
            block(camera)
            camera.unlockForConfiguration()
        } catch {
            print("Error for camera lockForConfiguration: \(error)")
        }
        lock.signal()
    }
    
    /// Starts capturing
    public func startSession() {
        lock.wait()
        session.startRunning()
        if multitpleSessions, let session = audioSession { session.startRunning() }
        lock.signal()
    }
    
    /// Stops capturing
    public func stopSession() {
        lock.wait()
        session.stopRunning()
        if multitpleSessions, let session = audioSession { session.stopRunning() }
        lock.signal()
    }
    
    /// Resets benchmark record data
    public func resetBenchmark() {
        lock.wait()
        capturedFrameCount = 0
        totalCaptureFrameTime = 0
        lock.signal()
    }
    
}

extension MetalCamera: MetalImageSource {
    @discardableResult
    public func add<T: MetalImageConsumer>(consumer: T) -> T {
        lock.wait()
        _consumers.append(consumer)
        lock.signal()
        consumer.add(source: self)
        return consumer
    }
    
    public func add(consumer: MetalImageConsumer, at index: Int) {
        lock.wait()
        _consumers.insert(consumer, at: index)
        lock.signal()
        consumer.add(source: self)
    }
    
    public func remove(consumer: MetalImageConsumer) {
        lock.wait()
        if let index = _consumers.firstIndex(where: { $0 === consumer }) {
            _consumers.remove(at: index)
            lock.signal()
            consumer.remove(source: self)
        } else {
            lock.signal()
        }
    }
    
    public func removeAllConsumers() {
        lock.wait()
        let consumers = _consumers
        _consumers.removeAll()
        lock.signal()
        for consumer in consumers {
            consumer.remove(source: self)
        }
    }
}


extension MetalCamera: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Audio
        if output is AVCaptureAudioDataOutput {
            lock.wait()
            let paused = _isPaused
            let currentAudioConsumer = _audioConsumer
            lock.signal()
            if !paused,
                let consumer = currentAudioConsumer {
                consumer.newAudioSampleBufferAvailable(sampleBuffer)
            }
            return
        }
        
        // Video
        lock.wait()
        let paused = _isPaused
        let consumers = _consumers
        let willTransmit = _willTransmitTexture
        let preprocessVideo = _preprocessVideo
        let cameraPosition = camera.position
        
        let isCameraPhoto = _needPhoto
        if _needPhoto { _needPhoto = false }
        
        let capturePhotoCompletion = _capturePhotoCompletion
        if _capturePhotoCompletion != nil { _capturePhotoCompletion = nil }
        
        let startTime = _benchmark ? CACurrentMediaTime() : 0
        lock.signal()
        
        guard !paused, !consumers.isEmpty else { return }
        
        preprocessVideo?(sampleBuffer)
        
        guard let texture = texture(with: sampleBuffer) else {
            if let completion = capturePhotoCompletion {
                let error = NSError(domain: "BBMetalCameraErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Can not get Metal texture"])
                let info = MetalFilterCompletionInfo(result: .failure(error),
                                                       sampleTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer),
                                                       cameraPosition: cameraPosition,
                                                       isCameraPhoto: isCameraPhoto)
                completion(info)
            }
            return
        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if let completion = capturePhotoCompletion {
            var result: Result<MTLTexture, Error>
            let filter = MetalPassThroughFilter(createTexture: true)
            if let metalTexture = filter.filteredTexture(with: texture.metalTexture) {
                result = .success(metalTexture)
            } else {
                let error = NSError(domain: "BBMetalCameraErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "Can not get Metal texture"])
                result = .failure(error)
            }
            let info = MetalFilterCompletionInfo(result: result,
                                                   sampleTime: sampleTime,
                                                   cameraPosition: cameraPosition,
                                                   isCameraPhoto: isCameraPhoto)
            completion(info)
        }
        
        willTransmit?(texture.metalTexture, sampleTime)
        let output = MetalDefaultTexture(metalTexture: texture.metalTexture,
                                           sampleTime: sampleTime,
                                           cameraPosition: cameraPosition,
                                           isCameraPhoto: isCameraPhoto,
                                           cvMetalTexture: texture.cvMetalTexture)
        for consumer in consumers { consumer.newTextureAvailable(output, from: self) }
        
        // Benchmark
        if startTime != 0 {
            lock.wait()
            capturedFrameCount += 1
            if capturedFrameCount > ignoreInitialFrameCount {
                totalCaptureFrameTime += CACurrentMediaTime() - startTime
            }
            lock.signal()
        }
    }
    
    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Camera drops \(output is AVCaptureAudioDataOutput ? "audio" : "video") sample buffer")
    }
    
    private func texture(with sampleBuffer: CMSampleBuffer) -> MetalVideoTextureItem? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        #if !targetEnvironment(simulator)
        var cvMetalTextureOut: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                               textureCache,
                                                               imageBuffer,
                                                               nil,
                                                               .bgra8Unorm, // camera ouput BGRA
                                                               width,
                                                               height,
                                                               0,
                                                               &cvMetalTextureOut)
        if result == kCVReturnSuccess,
            let cvMetalTexture = cvMetalTextureOut,
            let texture = CVMetalTextureGetTexture(cvMetalTexture) {
            return MetalVideoTextureItem(metalTexture: texture, cvMetalTexture: cvMetalTexture)
        }
        #endif
        return nil
    }
}


extension MetalCamera: AVCapturePhotoCaptureDelegate {
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            
            self._blockCompletionPhoto?(nil, error)
        }
        else
        {
            if let dataImage = photo.fileDataRepresentation()
            {
                let image = UIImage(data: dataImage)
                self._blockCompletionPhoto?(image, nil)
            }
            else
            {
                self._blockCompletionPhoto?(nil, nil)
            }
        }
        
    }
    
    private func rotatedTexture(with inTexture: MTLTexture, angle: Float) -> MTLTexture? {
        let source = MetalStaticImageSource(texture: inTexture)
        let filter = MetalRotateFilter(angle: angle, fitSize: true)
        source.add(consumer: filter).runSynchronously = true
        source.transmitTexture()
        return filter.outputTexture
    }
}


extension MetalCamera: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        metadataObjectDelegate?.camera(self, didOutput: metadataObjects)
    }
}



