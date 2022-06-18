//
//  CameraPreviewViewController.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 18/06/22.
//

import UIKit
import AVFoundation

enum PlayerState {
    case pause
    case play
    case replay
}

class CameraPreviewViewController: UIViewController {

    // MARK: PROPERTIES -
    
    var videoAsset: AVAsset?
    var player: AVPlayer?
    var playerState: PlayerState? = .play
    
    lazy var playerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playButtonTapped))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        
        return view
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setUpVideoPlayer()
        }
        
        /// It plays the video again once it reached its end
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem, queue: .main) { [weak self] _ in
            
            self?.playButton.isHidden = false
            self?.playButton.setImage(UIImage(named: "ic_replay")?.withRenderingMode(.alwaysTemplate), for: .normal)
            self?.playButton.tintColor = .white
            
            self?.playerState = .replay
        }
        
    }
    
    deinit {
        player = nil
    }
    
    // MARK: FUNCTIONS -
    
    func setUpViews(){
        view.backgroundColor = .black
        view.addSubview(playerView)
        view.addSubview(closeButton)
        view.addSubview(sliderView)
        view.addSubview(playButton)
    }
    
    func setUpConstraints(){
        playerView.pin(to: view)
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            sliderView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            sliderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderView.heightAnchor.constraint(equalToConstant: 40),
            
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func setUpVideoPlayer(){
        guard let asset = videoAsset else { return }
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = self.playerView.bounds
        self.playerView.layer.addSublayer(playerLayer)
        player?.play()
        
        // Adding player observer for changes
        if let duration = player?.currentItem?.duration {
            let seconds = CMTimeGetSeconds(duration)
            
            let secondText = String(format: "%02d", Int(seconds) % 60)
            let minuteText = String(format: "%02d", Int(seconds) / 60)
            
            sliderView.endCountLabel.text = "\(minuteText):\(secondText)"
        }
        
        // Tracking slider base on video progress
        let interval = CMTime(value: 1, timescale: 2)
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { time in
            let seconds = CMTimeGetSeconds(time)
            
            let secondString = String(format: "%02d", Int(seconds.truncatingRemainder(dividingBy: 60)))
            let minuteString = String(format: "%02d", Int(seconds / 60))
            
            self.sliderView.startCountLabel.text = "\(minuteString):\(secondString)"
            
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

extension CameraPreviewViewController: PlayerSliderActionDelegate {
    
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