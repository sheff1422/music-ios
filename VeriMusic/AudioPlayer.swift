//
//  AudioPlayer.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/12/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation
import AVFoundation


class AudioPlayer: NSObject{
    
    enum PlaybackState {
        case play
        case pause
        case stop
    }
    
    enum PlaybackOption {
        case continious
        case shuffle
        case `repeat`
    }
    
    var state: PlaybackState = .stop
    var option: PlaybackOption = .continious
    
    fileprivate var player: AVQueuePlayer!
    var currentAudio: TrackList?{
        didSet{
            switch self.currentAudio {
            case .some:
                
                let caURL = self.currentAudio!.url
                //let URL = caURL.scheme! + "://" + caURL.host! + caURL.path!
                //let nURL = NSURL(string: URL)
                var error: NSError?
                self.player = AVQueuePlayer(playerItem: AVPlayerItem(url: caURL as URL))
                //self.player.replaceCurrentItemWithPlayerItem(AVPlayerItem(URL: caURL))
 
                switch error{
                case .some:
                    print("Error while creating AVAudioPlayer with url \(self.currentAudio!.url): \(error!.localizedDescription)")
                    
                case .none:
                    print("none\(error)")
                    return
                }
            default:
                return
            }
        }
    }
    
    var duration : Double {
        get {
            switch self.player.currentItem {
            case .some:
                return Double(CMTimeGetSeconds(self.player.currentItem!.asset.duration))
                
            case .none:
                return 0
            }
        }
    }
    
    var currentTime : Double{
        get {
            switch self.player.currentItem {
            case .some:
                return Double(CMTimeGetSeconds(self.player.currentItem!.currentTime()))
                
            case .none:
                return 0
            }
        }
    }
    
    func seekToTime(_ time: Double){
        let targetTime = CMTimeMakeWithSeconds(time, Int32(NSEC_PER_SEC))
        self.player.seek(to: targetTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    
    class var sharedInstance : AudioPlayer {
        struct Static {
            static let instance : AudioPlayer = AudioPlayer()
        }
        return Static.instance
    }
    
    func play(){
        self.player.play()
        self.state = .play
    }
    
    func pause(){
        self.player.pause()
        self.state = .pause
    }
    
    func stop(){
        self.player.pause()
        self.state = .stop
    }
    
    
}
