//
//  PlayerControlBar.swift
//  music
//
//  Created by Atakishiyev Orazdurdy on 5/19/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit

class PlayerControlBar: UIToolbar {
    
    fileprivate var playButton: UIBarButtonItem?
    fileprivate var pauseButton: UIBarButtonItem?
    fileprivate var backButton: UIBarButtonItem?
    fileprivate var nextButton: UIBarButtonItem?
    
    fileprivate let fixedSpace: UIBarButtonItem = {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 42
        return space
        }()
    
    var player: MusicPlayer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        playButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(PlayerControlBar.play))
        pauseButton = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(PlayerControlBar.pause))
        backButton = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(PlayerControlBar.back))
        nextButton = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(PlayerControlBar.next as (PlayerControlBar) -> () -> ()))
        
        self.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            backButton!,
            fixedSpace,
            playButton!,
            fixedSpace,
            nextButton!,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        ]
        
        self.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        
    }
    
    func play() {
        if let player = self.player {
            self.items?[3] = pauseButton!
            if player.paused() {
                MusicPlayer.initSession()
                player.play()
                
            }
        }
    }
    
    func pause() {
        if let player = self.player {
            self.items?[3] = playButton!
            if !player.paused() {
                player.pause()
                
            }
        }
    }
    
    func back() {
        if let player = self.player {
            player.previousTrack()
        }
    }
    
    func next() {
        if let player = self.player {
            player.nextTrack()
        }
    }
    
}


