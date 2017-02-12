//
//  MusicPlayer.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/17/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit

import AVFoundation
import MediaPlayer

private func mod(_ n: Int, m: Int) -> Int {
    assert(m > 0, "m must be positive")
    return n >= 0 ? n % m : m - (-n) % m
}

private extension Array {
    mutating func shuffle() {
        if self.count > 0 {
            for i in 0..<(count - 1) {
                let j = Int(arc4random_uniform(UInt32(count - i))) + i
                swap(&self[i], &self[j])
            }
        }
    }
}

protocol MusicPlayerDelegate {
    func player(_ playlistPlayer: MusicPlayer, didChangeCurrentPlaylistItem playlistItem: PlaylistItem?)
}

class MusicPlayer: NSObject {
    
    let avQueuePlayer:AVQueuePlayer = AVQueuePlayer()
    
    var playlist: [PlaylistItem] = []
    var delegate: MusicPlayerDelegate?
    
    var currentItem: PlaylistItem? {
        return avQueuePlayer.currentItem as? PlaylistItem
    }
    
    override init() {
        super.init()
        avQueuePlayer.actionAtItemEnd = .none
        NotificationCenter.default.addObserver(self, selector: #selector(MusicPlayer.playNextTrack(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: avQueuePlayer.currentItem)
    }
    
    /**
    Initialises the audio session
    */
    class func initSession() {
        
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "audioSessionInterrupted:", name: AVAudioSessionInterruptionNotification, object: AVAudioSession.sharedInstance())
        var error:NSError?
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        if let nonNilError = error {
            print("an error occurred when audio session category.\n \(error)")
        }
        
        var activationError:NSError?
        try! AVAudioSession.sharedInstance().setActive(true)
    }
    
    func play() {
        if avQueuePlayer.currentItem == nil {
            if let first = playlist.first {
                avQueuePlayer.replaceCurrentItem(with: first)
                delegate?.player(self, didChangeCurrentPlaylistItem: self.currentItem)
            }
        }
        avQueuePlayer.play()
    }
    
    func pause() {
        avQueuePlayer.pause()
    }
    
    func paused() -> Bool {
        if avQueuePlayer.currentItem != nil && avQueuePlayer.rate != 0 {
            return false
        } else {
            return true
        }
    }
    
    func playNextTrack(_ notification: Notification) {
        var repeatPlay: Bool = false
        if let bool = UserDefaults.standard.value(forKey: "repeat") as? Bool {
            repeatPlay = bool
        }
        
        if(repeatPlay){
            seekToTime()
        }else{
            self.nextTrack()
        }
    }
    
    func seekToTime(){
        let targetTime = CMTimeMakeWithSeconds(0.0, Int32(NSEC_PER_SEC))
        self.avQueuePlayer.seek(to: targetTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    func nextTrack() {
        var next: PlaylistItem
        
        if let i = playlist.index(of:avQueuePlayer.currentItem as! PlaylistItem) {
            next = playlist[mod(i + 1, m: playlist.count)]
        } else {
            next = playlist[0]
        }
        next.seek(to: kCMTimeZero)
        
        let playing = avQueuePlayer.rate > 0
        
        avQueuePlayer.replaceCurrentItem(with: next)
        delegate?.player(self, didChangeCurrentPlaylistItem: self.currentItem)
        
        if playing {
            avQueuePlayer.play()
        }
    }
    
    func previousTrack() {
        var previous: PlaylistItem
        
        if let i = playlist.index(of:avQueuePlayer.currentItem as! PlaylistItem) {
            previous = playlist[mod(i - 1, m: playlist.count)]
        } else {
            previous = playlist[0]
        }
        previous.seek(to: kCMTimeZero)
        
        let playing = avQueuePlayer.rate > 0
        
        avQueuePlayer.replaceCurrentItem(with: previous)
        delegate?.player(self, didChangeCurrentPlaylistItem: self.currentItem)
        
        if playing {
            avQueuePlayer.play()
        }
    }
    
    func setCurrentItemFromIndex(_ index: Int) {
        let item = playlist[index]
        if item != currentItem {
            item.seek(to: kCMTimeZero)
        }
        avQueuePlayer.replaceCurrentItem(with: item)
        delegate?.player(self, didChangeCurrentPlaylistItem: self.currentItem)
    }
    
    func shuffle() {
        playlist.shuffle()
    }

    func remoteControlReceivedWithEvent(_ receivedEvent:UIEvent)  {
        if (receivedEvent.type == .remoteControl) {
            switch receivedEvent.subtype {
            case .remoteControlTogglePlayPause:
                if avQueuePlayer.rate > 0.0 {
                    avQueuePlayer.pause()
                } else {
                    avQueuePlayer.play()
                }
            case .remoteControlPlay:
                avQueuePlayer.play()
            case .remoteControlPause:
                avQueuePlayer.pause()
            case .remoteControlNextTrack:
                self.nextTrack()
                avQueuePlayer.play()
            case .remoteControlPreviousTrack:
                self.previousTrack()
                avQueuePlayer.play()
            default:
                print("received sub type \(receivedEvent.subtype) Ignoring")
            }
        }
    }
    
    //MARK: - Notifications
    func audioSessionInterrupted(_ notification:Notification)
    {
        print("interruption received: \(notification)")
    }
    
    //response to remote control events
    
    
    
    
    
}
