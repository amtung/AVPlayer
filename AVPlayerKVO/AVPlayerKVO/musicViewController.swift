//
//  musicViewController.swift
//  AVPlayerKVO
//
//  Created by Annie Tung on 1/27/17.
//  Copyright © 2017 Annie Tung. All rights reserved.
//

import UIKit
import AVFoundation

private var kvoContext = 0

class musicViewController: UIViewController {
    
    // MARK: - Properties and outlets
    
    var player: AVPlayer!
    var userPlaying: Bool = false
    var userPlayRate: Float = 1.0
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var positionSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadAssetFromFile(stringURL: "debussy.mp3")
    }
    
    // MARK: - Utility
    
    func updatePositionSlider() {
        guard let item = player.currentItem else { return }
        let currentPlace = Float(item.currentTime().seconds / item.duration.seconds)
        self.positionSlider.value = currentPlace
    }
    
    func loadAssetFromFile(stringURL: String) {
        guard let dot = stringURL.range(of: ".") else { return }
        let fileParts = (resource: stringURL.substring(to: dot.lowerBound), extension: stringURL.substring(from: dot.upperBound))
        
        if let fileURL = Bundle.main.url(forResource: fileParts.resource, withExtension: fileParts.extension) {
            let asset = AVURLAsset(url: fileURL)
            let playerItem = AVPlayerItem(asset: asset)
            self.player = AVPlayer(playerItem: playerItem)
            
            playerItem.addObserver(self, forKeyPath: "status", options: .new, context: &kvoContext)
            
            let timeInterval = CMTime(value: 1, timescale: 2)
            player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main, using: { (time) in
                print(time)
                self.updatePositionSlider()
            })
        }
    }
    
    // MARK: - Action
    
    @IBAction func sliderDidChangeValue(_ sender: UISlider) {
        guard let item = player.currentItem else { return }
        let newPosition = Double(sender.value) * item.duration.seconds
        
        player.seek(to: CMTime(seconds: newPosition, preferredTimescale: 1000))
        player.playImmediately(atRate: userPlayRate)
    }
    
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if !userPlaying {
            player.playImmediately(atRate: userPlayRate)
            sender.setTitle("Pause", for: .normal)
        } else {
            player.pause()
            sender.setTitle("Play", for: .normal)
        }
        userPlaying = !userPlaying
    }
    
    // MARK: - KVO
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        if context == &kvoContext {
            if keyPath == "status",
                let item = object as? AVPlayerItem {
                if item.status == .readyToPlay {
                    playPauseButton.isEnabled = true
                }
            }
        }
    }
}
