//
//  ShortsPreviewController.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 03/07/22.
//

import UIKit
import AVFoundation

class ShortsPreviewController: UIViewController {

    // MARK: PROPERTIES -
    
    var videoAssets: [AVAsset] = []
    var speedArr: [Double] = []
    var player: AVPlayer?
    var playerState: PlayerState? = .play
    var viewModel: CameraViewModel!
    
    lazy var playerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playButtonTapped))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    let processingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Processing.."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.isHidden = true
        return label
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "ic_close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.8)
        button.layer.cornerRadius = 20
        button.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        return button
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        button.isHidden = true
        button.setImage(UIImage(named: "ic_play")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .black.withAlphaComponent(0.8)
        
        button.layer.cornerRadius = 40
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3
        
        return button
    }()
    
    lazy var sliderView: PlayerSliderView = {
        let view = PlayerSliderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    // MARK: MAIN -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpConstraints()
        processVideos()
        
        /// It plays the video again once it reached its end
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) { [weak self] _ in
            
            self?.playButton.isHidden = false
            self?.playButton.setImage(UIImage(named: "ic_replay")?.withRenderingMode(.alwaysTemplate), for: .normal)
            self?.playButton.tintColor = .white
            
            self?.playerState = .replay
        }
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        view.addSubview(playerView)
        playerView.addSubview(processingLabel)
        
        view.addSubview(closeButton)
        view.addSubview(sliderView)
        
        view.addSubview(playButton)
    }
    
    func setUpConstraints(){
        processingLabel.pin(to: playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.heightAnchor.constraint(equalToConstant: view.frame.size.width * (16/9)),
            playerView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            sliderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            sliderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderView.heightAnchor.constraint(equalToConstant: 40),
            
            playButton.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func processVideos(){
        
        /*
            1. convert asset to url (save asset to temporary memory).
            2. use that url to change the speed of original video (NOTE: it will return us assets not url).
            3. again convert thoes processed assets to url.
            
         Now because we have multiple assets we need to repeat this for each asset
            
            4. after getting multiple processed urls merge them and get final url for preview.
         
            5. Check for the selected duration for a video and trim it!
         
         */
        
        
        var processedURL: [URL] = []
        processingLabel.isHidden = false
        
        let group1 = DispatchGroup()
        group1.enter()
        for i in 0..<videoAssets.count {
            let asset = videoAssets[i]
            AudioVideoManager.shared.getURLFromAsset(asset: asset) {
                // progress
            } completionHandler: { url in
                guard let url = url else {
                    return
                }
                let speed = self.speedArr[i]
                AudioVideoManager.shared.changeVideoSpeed(videoUrl: url, videoSpeed: speed ,audioSpeed: speed) { asset in
                    guard let asset = asset else {
                        return
                    }
                    AudioVideoManager.shared.getURLFromAsset(asset: asset) {
                        // progress
                    } completionHandler: { url in
                        guard let url = url else {
                            return
                        }
                        processedURL.append(url)
                        if i == self.videoAssets.count - 1 {
                            group1.leave()
                        }
                    }
                }
            }
        }
        
        group1.notify(queue: .main){
            print(processedURL)
            if let url = MetalCameraFileManager.temporaryPath("\(arc4random()).mp4") {
                AudioVideoManager.shared.mergeVideos(videoUrls: processedURL, exportUrl: url) { progress in
                    self.processingLabel.text = "processing...\(Int(progress * 100.0))"
                } completion: { url, error in
                    let selectedDuration = self.viewModel.recordingDuration
                    guard let url = url else { return }
                    AudioVideoManager.shared.cropVideo(sourceURL: url, length: Float(selectedDuration)) { url in
                        DispatchQueue.main.async {
                            self.processingLabel.isHidden = true
                            self.setUpPlayer(with: url)
                        }
                    }
                }

            }
            
        }
        
    }
    
    func setUpPlayer(with url: URL?){
        guard let url = url else {
            return
        }
        player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        playerLayer.frame = self.playerView.bounds
        self.playerView.layer.addSublayer(playerLayer)
        player?.play()
        
        // Adding player observer for changes
        if let duration = player?.currentItem?.duration {
            let seconds = CMTimeGetSeconds(duration)
            
            if !seconds.isNaN {
                let secondText = String(format: "%02d", Int(seconds) % 60)
                let minuteText = String(format: "%02d", Int(seconds) / 60)
                
                sliderView.playerTimerLabel.text = "\(minuteText):\(secondText)"
            }
        }
        
        // Tracking slider base on video progress
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { time in
            let seconds = CMTimeGetSeconds(time)
            
            let secondString = String(format: "%02d", Int(seconds.truncatingRemainder(dividingBy: 60)))
            let minuteString = String(format: "%02d", Int(seconds / 60))
            
            self.sliderView.playerTimerLabel.text = "\(minuteString):\(secondString)"
            
            if let duration = self.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                self.sliderView.playerSlider.value = Float(seconds / durationSeconds)
            }
        })
    }
    
    // MARK: - ACTIONS
    
    @objc func dismissController(){
        player?.pause()
        dismiss(animated: true)
    }
    
    @objc func playButtonTapped(){
        if playerState == .pause {
            player?.play()
            playButton.isHidden = true
            playerState = .play
        } else if playerState == .play {
            player?.pause()
            playButton.isHidden = false
            playerState = .pause
        } else {
            // set play icon and hide playbutton
            self.player?.seek(to: CMTime.zero)
            self.player?.play()
            
            self.playButton.setImage(UIImage(named: "ic_play")?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.playButton.tintColor = .white
            
            playButton.isHidden = true
            playerState = .play
        }
    }

}

extension ShortsPreviewController: PlayerSliderActionDelegate {
    
    func didScrub(sliderValue: Double) {
        
        if let duration = player?.currentItem?.duration {
            
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(sliderValue * totalSeconds)
            
            let seekTo = CMTime(value: Int64(value), timescale: 1)
            
            player?.seek(to: seekTo, completionHandler: { finished in
                print("Finish seeking")
            })
        }
        
    }
    
}
