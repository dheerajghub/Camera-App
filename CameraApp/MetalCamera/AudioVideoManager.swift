//
//  AudioVideoManager.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 12/06/22.
//

import UIKit
import AVFoundation
import UniformTypeIdentifiers

class AudioVideoManager: NSObject {
    
    static let shared = AudioVideoManager()
    
    typealias Completion = (URL?, Error?) -> Void
    
    typealias Progress = (Float) -> Void
    
    func mergeVideos(videoUrls: [URL], exportUrl: URL, preset: String? = nil, progress: @escaping Progress, completion: @escaping Completion) {
        
        let videoAssets: [AVAsset] = videoUrls.map { (url) -> AVAsset in
            return AVAsset(url: url)
        }
        
        var insertTime = CMTime.zero
        var arrayLayerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        var outputSize = CGSize.init(width: 0, height: 0)
        
        // Determine video output size
        for videoAsset in videoAssets {
            guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else { return }
            
            let assetInfo = orientationFromTransform(transform: videoTrack.preferredTransform)
            
            var videoSize = videoTrack.naturalSize
            if assetInfo.isPortrait == true {
                videoSize.width = videoTrack.naturalSize.height
                videoSize.height = videoTrack.naturalSize.width
            }
            
            if videoSize.height > outputSize.height {
                outputSize = videoSize
            }
        }
        
        if outputSize.width == 0 || outputSize.height == 0 {
            outputSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        
        // Silence sound (in case of video has no sound track)
        guard let blankAudioUrl = Bundle.main.url(forResource: "Blank", withExtension: "mp3") else {
            completion(nil, nil)
            return
        }
        let blankAudio = AVAsset(url: blankAudioUrl)
        let blankAudioTrack = blankAudio.tracks(withMediaType: .audio).first
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        for videoAsset in videoAssets {
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else { continue }
            
            // Get audio track
            var audioTrack: AVAssetTrack?
            
            if videoAsset.tracks(withMediaType: .audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: .audio).first
            } else {
                audioTrack = blankAudioTrack
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = CMTime.zero
                let duration = videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration), of: videoTrack, at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration), of: audioTrack, at: insertTime)
                }
                
                // Add instruction for video track
                let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!, asset: videoAsset, standardSize: outputSize, atTime: insertTime)
                
                // Hide video track before changing to new track
                let endTime = CMTimeAdd(insertTime, duration)
                layerInstruction.setOpacity(0, at: endTime)

                arrayLayerInstructions.append(layerInstruction)
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            } catch {
                print("Load track error")
            }
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = outputSize
        
        startExport(mixComposition, mainComposition, exportUrl, preset: (preset ?? AVAssetExportPreset1920x1080), progress: progress, completion: completion)
    }
    
    func mergeAudioTo(videoUrl: URL, audioUrl: URL, exportUrl: URL, progress: @escaping Progress, completion: @escaping Completion) {
        let videoAsset = AVAsset(url: videoUrl)
        let audioAsset = AVAsset(url: audioUrl)
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        // Get video track
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            print("[Error]: Video not found.")
            completion(nil, nil)
            return
        }
        
        // Get audio track
        guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
            print("[Error]: Audio not found.")
            completion(nil, nil)
            return
        }
        
        // Init video & audio composition track
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        do {
            // Add video track to video composition at specific time
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
            
            // Add audio track to audio composition at specific time
            try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: audioTrack, at: .zero)
            
        } catch {
            print(error.localizedDescription)
        }
        
        startExport(mixComposition, nil, exportUrl, progress: progress, completion: completion)
    }
    
    func changeVideoSpeed(videoUrl: URL,videoSpeed:Double,audioSpeed:Double, _ completionhandler: @escaping(AVAsset?) -> ()) {
        let videoAsset = AVAsset(url: videoUrl)
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        // Get video track
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else {
            print("[Error]: Video not found.")
            completionhandler(nil)
            return
        }
        
        // Get audio track
        var audioTrack: AVAssetTrack?
        
        if videoAsset.tracks(withMediaType: .audio).count > 0 {
            audioTrack = videoAsset.tracks(withMediaType: .audio).first
        }
        
        // Init video & audio composition track
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                                   preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let finalVideoDuration = Double(videoAsset.duration.value) / videoSpeed
        let finalAudioDuration = Double(videoAsset.duration.value) / audioSpeed
        
        // slowdown or fast forward
        let scaledVideoDuration = CMTimeMake(value: Int64(finalVideoDuration), timescale: videoAsset.duration.timescale)
        let scaledAudioDuration = CMTimeMake(value: Int64(finalAudioDuration), timescale: videoAsset.duration.timescale)
        
        do {
            // Add video track to video composition at specific time
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
            
            videoCompositionTrack?.scaleTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), toDuration: scaledVideoDuration)
            
            // Add audio track to audio composition at specific time
            if let audioTrack = audioTrack {
                try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: audioTrack, at: .zero)
                
                audioCompositionTrack?.scaleTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), toDuration: scaledAudioDuration)
            }
            
            completionhandler(mixComposition)
        } catch {
            completionhandler(nil)
        }
    }
    
    func trimVideo(videoAsset: AVAsset, startTime: CMTime, endTime: CMTime, exportUrl: URL, progress: @escaping Progress, completion: @escaping Completion) {
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        startExport(videoAsset, nil, exportUrl, timeRange: timeRange, progress: progress, completion: completion)
    }
    
    func addLayerToVideo(videoAsset: AVAsset, overlayImage: UIImage, exportUrl: URL, preset: String? = nil, progress: @escaping Progress, completion: @escaping Completion) {
                
        var outputSize = CGSize.init(width: 0, height: 0)
        var arrayLayerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        
        // Determine video output size
        guard let videoTrack = videoAsset.tracks(withMediaType: .video).first else { return }
        
        let assetInfo = orientationFromTransform(transform: videoTrack.preferredTransform)
        
        var videoSize = videoTrack.naturalSize
        
        if assetInfo.isPortrait == true {
            videoSize.width = videoTrack.naturalSize.height
            videoSize.height = videoTrack.naturalSize.width
        }
        
        if videoSize.height > outputSize.height {
            outputSize = videoSize
        }
        
        if outputSize.width == 0 || outputSize.height == 0 {
            outputSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
        
        // Silence sound (in case of video has no sound track)
//        let blankAudioUrl = Bundle.main.url(forResource: "blank", withExtension: "wav")!
//        let blankAudio = AVAsset(url: blankAudioUrl)
//        let blankAudioTrack = blankAudio.tracks(withMediaType: .audio).first
        
        // Init composition
        let mixComposition = AVMutableComposition.init()
        
        // Get audio track
        var audioTrack: AVAssetTrack?
        
        if videoAsset.tracks(withMediaType: .audio).count > 0 {
            audioTrack = videoAsset.tracks(withMediaType: .audio).first
        } else {
            //audioTrack = blankAudioTrack
        }
        
        // Init video & audio composition track
        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        do {
            // Add video track to video composition at specific time
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: videoTrack, at: .zero)
            
            // Add audio track to audio composition at specific time
            if let audioTrack = audioTrack {
                try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: videoAsset.duration), of: audioTrack, at: .zero)
            }
            
            // Add instruction for video track
            let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack!, asset: videoAsset, standardSize: outputSize, atTime: .zero)
            
            // Hide video track before changing to new track
            let endTime = CMTimeAdd(.zero, videoAsset.duration)
            layerInstruction.setOpacity(0, at: endTime)
            
            arrayLayerInstructions.append(layerInstruction)
            
        } catch {
            completion(exportUrl,error)
            return
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoAsset.duration)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainComposition.renderSize = outputSize
        
        let parentLayer = CALayer.init()
        parentLayer.frame = CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
        
        let videoLayer = CALayer.init()
        videoLayer.frame = CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
        parentLayer.addSublayer(videoLayer)
        
        // add image
        let overlayLayer = CALayer.init()
        overlayLayer.contentsGravity = .resizeAspect
        overlayLayer.contents = overlayImage.cgImage
        overlayLayer.frame = CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
        overlayLayer.masksToBounds = true
        parentLayer.addSublayer(overlayLayer)
        
        mainComposition.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        startExport(mixComposition, mainComposition, exportUrl, preset: (preset ?? AVAssetExportPresetMediumQuality), progress: progress, completion: completion)
    }
    
    func applyFilterToVideo(_ videoUrl: URL, filter: CIFilter, exportUrl: URL, preset: String? = nil, progress: @escaping Progress, completion: @escaping Completion) {
        let videoAsset = AVAsset(url: videoUrl)
        var context: CIContext!
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext()
        }
        
        let videoComposition = AVMutableVideoComposition(asset: videoAsset, applyingCIFiltersWithHandler: { request in
            let source = request.sourceImage.clampedToExtent()
            filter.setValue(source, forKey: kCIInputImageKey)

            let outputImage = filter.outputImage?.cropped(to: source.extent) ?? source

            request.finish(with: outputImage, context: context)
        })
        
        startExport(videoAsset, videoComposition, exportUrl, preset: (preset ?? AVAssetExportPreset1920x1080), progress: progress, completion: completion)
    }
    
    func addWatermark(videoAsset: AVAsset, watermarkImage: UIImage, exportUrl: URL, preset: String? = nil, progress: @escaping Progress, completion: @escaping Completion) {
        guard let watermarkCIImage = CIImage(image: watermarkImage) else {
            print("[Error]: watermarkCIImage could not create.")
            return
        }
        
        var context: CIContext!
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext()
        }
        let overCompositingFilter = CIFilter(name: "CISourceOverCompositing")!

        let videoComposition = AVMutableVideoComposition(asset: videoAsset) { (request) in
            let source = request.sourceImage.clampedToExtent()
            
            overCompositingFilter.setValue(source, forKey: kCIInputBackgroundImageKey)
            overCompositingFilter.setValue(watermarkCIImage, forKey: kCIInputImageKey)
            
            let outputImage = overCompositingFilter.outputImage?.cropped(to: source.extent) ?? source

            request.finish(with: outputImage, context: context)
        }

        startExport(videoAsset, videoComposition, exportUrl, preset: (preset ?? AVAssetExportPresetHighestQuality), progress: progress, completion: completion)
    }
    
    func getURLFromAsset(asset: AVAsset?, _ progress: @escaping() -> (), completionHandler: @escaping(URL?) -> ()) {
        
        guard let asset = asset else {
            completionHandler(nil)
            return
        }
        
        if let url = MetalCameraFileManager.temporaryPath("\(arc4random()).mp4") {
            if let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) {
                session.outputURL = url
                session.outputFileType = AVFileType.mov
                progress()
                session.exportAsynchronously {
                    completionHandler(url)
                }
            }
        }
    }
    
    func removeAudioFromVideo(_ videoURL: URL , completionHandler: @escaping(URL?) -> ()) {
        let inputVideoURL: URL = videoURL
        let sourceAsset = AVURLAsset(url: inputVideoURL)
        let sourceVideoTrack: AVAssetTrack? = sourceAsset.tracks(withMediaType: AVMediaType.video)[0]
            let composition : AVMutableComposition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let x: CMTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: sourceAsset.duration)
        _ = try? compositionVideoTrack!.insertTimeRange(x, of: sourceVideoTrack!, at: CMTime.zero)
        guard let mutableVideoURL = MetalCameraFileManager.temporaryPath("test.mp4") else { return }
        let exporter: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
        exporter.outputFileType = AVFileType.mp4
        exporter.outputURL = mutableVideoURL
        exporter.exportAsynchronously(completionHandler:
            {
                switch exporter.status
                {
                case AVAssetExportSession.Status.failed:
                    print("failed \(String(describing: exporter.error))")
                case AVAssetExportSession.Status.cancelled:
                    print("cancelled \(String(describing: exporter.error))")
                case AVAssetExportSession.Status.unknown:
                    print("unknown\(String(describing: exporter.error))")
                case AVAssetExportSession.Status.waiting:
                    print("waiting\(String(describing: exporter.error))")
                case AVAssetExportSession.Status.exporting:
                    print("exporting\(String(describing: exporter.error))")
                default:
                    completionHandler(mutableVideoURL)
                }
            })
    }
    
    func cropVideo(sourceURL: URL, length: Float, completionHandler: @escaping(URL?) -> ())
     {
         let manager = FileManager.default

         guard let documentDirectory = try? manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {return}
         let mediaType = "mp4"
         if mediaType == "mp4" as String {
             let asset = AVAsset(url: sourceURL as URL)
             let len = Float(asset.duration.value) / Float(asset.duration.timescale)
             print("video length: \(len) seconds")

             let start = 0.0
             let end = length

             var outputURL = documentDirectory.appendingPathComponent("output")
             do {
                 try manager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                 outputURL = outputURL.appendingPathComponent("\(UUID().uuidString).\(mediaType)")
             }catch let error {
                 print(error)
             }

             //Remove existing file
             _ = try? manager.removeItem(at: outputURL)


             guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
             exportSession.outputURL = outputURL
             exportSession.outputFileType = .mp4

             let startTime = CMTime(seconds: Double(start ), preferredTimescale: 1000)
             let endTime = CMTime(seconds: Double(end ), preferredTimescale: 1000)
             let timeRange = CMTimeRange(start: startTime, end: endTime)

             exportSession.timeRange = timeRange
             exportSession.exportAsynchronously{
                 switch exportSession.status {
                 case .completed:
                     completionHandler(outputURL)
                 case .failed:
                     print("failed \(exportSession.error)")

                 case .cancelled:
                     print("cancelled \(exportSession.error)")

                 default: break
                 }
             }
         }
     }
    
    deinit { print("TYAudioVideoManager deinit.") }
}


// MARK:- Private methods
extension AudioVideoManager {
    
    fileprivate func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    fileprivate func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset, standardSize: CGSize, atTime: CMTime) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform: transform)
        
        var aspectFillRatio:CGFloat = 1
        if assetTrack.naturalSize.height < assetTrack.naturalSize.width {
            aspectFillRatio = standardSize.height / assetTrack.naturalSize.height
        } else {
            aspectFillRatio = standardSize.width / assetTrack.naturalSize.width
        }
        
        if assetInfo.isPortrait {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor), at: atTime)
            
        } else {
            let scaleFactor = CGAffineTransform(scaleX: aspectFillRatio, y: aspectFillRatio)
            
            let posX = standardSize.width/2 - (assetTrack.naturalSize.width * aspectFillRatio)/2
            let posY = standardSize.height/2 - (assetTrack.naturalSize.height * aspectFillRatio)/2
            let moveFactor = CGAffineTransform(translationX: posX, y: posY)
            
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor).concatenating(moveFactor)
            
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                concat = fixUpsideDown.concatenating(scaleFactor).concatenating(moveFactor)
            }
            
            instruction.setTransform(concat, at: atTime)
        }
        return instruction
    }
    
    fileprivate func setOrientation(image: UIImage?, onLayer: CALayer, outputSize: CGSize) -> Void {
        guard let image = image else { return }
        
        if image.imageOrientation == UIImage.Orientation.up {
            // Do nothing
        } else if image.imageOrientation == UIImage.Orientation.left {
            let rotate = CGAffineTransform(rotationAngle: .pi/2)
            onLayer.setAffineTransform(rotate)
        } else if image.imageOrientation == UIImage.Orientation.down {
            let rotate = CGAffineTransform(rotationAngle: .pi)
            onLayer.setAffineTransform(rotate)
        } else if image.imageOrientation == UIImage.Orientation.right {
            let rotate = CGAffineTransform(rotationAngle: -.pi/2)
            onLayer.setAffineTransform(rotate)
        }
    }
    
    fileprivate func startExport(_ mixComposition: AVAsset, _ videoComposition: AVMutableVideoComposition? = nil,  _ exportUrl: URL, preset: String? = nil, timeRange: CMTimeRange? = nil, progress: @escaping Progress, completion: @escaping Completion) {
        
        // Init exporter
        let exporter = AVAssetExportSession.init(asset: mixComposition, presetName: (preset ?? AVAssetExportPresetHighestQuality))
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = AVFileType.mp4
        exporter?.shouldOptimizeForNetworkUse = true
        exporter?.videoComposition = videoComposition
        if let timeRange = timeRange {
            exporter?.timeRange = timeRange
        }
        
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
            let exportProgress: Float = exporter?.progress ?? 0.0
            DispatchQueue.main.async {
                progress(exportProgress)
            }
        })
        
        // Do export
        exporter?.exportAsynchronously(completionHandler: {
            progressTimer.invalidate()
            if exporter?.status == AVAssetExportSession.Status.completed {
                print("Exported file: \(exportUrl.absoluteString)")
                DispatchQueue.main.async {
                    completion(exportUrl, nil)
                }
            } else if exporter?.status == AVAssetExportSession.Status.failed {
                DispatchQueue.main.async {
                    completion(exportUrl, exporter?.error)
                }
            }
        })
    }
}

extension FileManager {
    
    func removeItemIfExisted(_ url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch {
                print("Failed to delete file")
            }
        }
    }
    
    func clearTmpDirectory() {
        do {
            let tmpDirectory = try contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach {[unowned self] file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try self.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }
}
