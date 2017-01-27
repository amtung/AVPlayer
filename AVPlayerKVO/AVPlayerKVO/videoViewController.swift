//
//  ViewController.swift
//  AVPlayerKVO
//
//  Created by Annie Tung on 1/25/17.
//  Copyright © 2017 Annie Tung. All rights reserved.
//

import UIKit
import AVFoundation

private var kvoContext = 0

class videoViewController: UIViewController {
    
    // MARK: - Properties and Outlets
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var positionSlider: UISlider!
    @IBOutlet weak var videoContainer: UIView!
    var avplayer: AVPlayer!
    var userPlayRate: Float = 1.0
    var isUserPlaying: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sample:http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
        
        if let url = URL(string: "https://content.uplynk.com/7dd85b057b134b14afdb3d710398c2a8.m3u8") {
            
            let playerItem = AVPlayerItem(url: url)
            playerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: &kvoContext)
            let player = AVPlayer(playerItem: playerItem)
            
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.videoContainer.bounds
            self.videoContainer.layer.addSublayer(playerLayer)
            
            self.avplayer = player
            
            let timeInterval = CMTime(value: 1, timescale: 2) // massive amount of time we need to represent as a rational # - 1/2
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time: CMTime) in
                print(time)
                self.updatePositionSlider()
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        guard let sublayers = self.videoContainer.layer.sublayers else { return }
        
        for layer in sublayers {
            layer.frame = self.videoContainer.bounds
        }
    }
    
    // MARK: - Utility
    
    func updatePositionSlider() {
        guard let item = avplayer.currentItem else { return }
        let currentPosition = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPosition
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }

        if context == &kvoContext {
            if let item = object as? AVPlayerItem {
                switch keyPath {
                case #keyPath(AVPlayerItem.status):
                    if item.status == .readyToPlay {
                        playPauseButton.isEnabled = true
                    }
                case #keyPath(AVPlayerItem.loadedTimeRanges):
                    for range in item.loadedTimeRanges {
                        print(range.timeRangeValue)
                    }
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Action
    
    @IBAction func sliderChangedValue(_ sender: UISlider) {
        guard let item = avplayer.currentItem else { return }
        let newPosition = Double(sender.value) * item.duration.seconds
        
        avplayer.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
        avplayer.playImmediately(atRate: userPlayRate)
    }
    
    @IBAction func rateChanged(_ sender: UISlider) {
        guard let item = avplayer.currentItem else { return }
        userPlayRate = sender.value
        
        if item.canPlayFastForward {
            print("Fast forwarding at rate \(userPlayRate)")
        }
        if item.canPlaySlowForward {
            print("Slow forwarding at rate \(userPlayRate)")
        }
        if isUserPlaying {
            avplayer.rate = userPlayRate
            print("New rate: \(avplayer.rate)")
        }
    }
    
    @IBAction func pauseButtonTapped(_ sender: UIButton) {
        if !isUserPlaying {
            avplayer.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
        } else {
            avplayer.pause()
            sender.setTitle("Play", for: .normal)
        }
        isUserPlaying = !isUserPlaying
    }
}
