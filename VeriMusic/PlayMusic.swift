//
//  PlayMusic.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/13/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit

class PlayMusic: UIViewController {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var restLabel: UILabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var lbl_title: UILabel!
    
    var currentPage: Int = 0
    fileprivate var previousPage: Int = 0
    var ticker: Foundation.Timer?
    var trackList = [TrackList]()
    var index = 0
    
    override var preferredContentSize: CGSize {
        get {
            if backView != nil && presentingViewController != nil {
                let height = presentingViewController!.view.bounds.size.height
                var size = CGSize(width: 200, height: height)
                return backView.sizeThatFits(presentingViewController!.view.bounds.size)
            }else
            {
                return super.preferredContentSize
            }
        }
        set {super.preferredContentSize = newValue}
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ticker = Foundation.Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayMusic.tick), userInfo: nil, repeats: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        refreshState()
        refreshPlayPauseButton()
        ProgressView.shared.hideProgressView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ticker?.invalidate()
    }
    
    @IBAction func progressSliderValueChanged(_ sender: AnyObject) {
        refreshTimeLabels()
        AudioPlayer.sharedInstance.seekToTime(Double(self.progressSlider.value))
    }
    
    func refreshState(){
        switch AudioPlayer.sharedInstance.currentAudio {
        case .some(let audio):
            self.lbl_title.text = "\(audio.artist) - \(audio.title)"
            self.progressSlider.minimumValue = 0.0
            self.progressSlider.maximumValue = Float(AudioPlayer.sharedInstance.duration)
            
        default:
            return
        }
        
        refreshPlayPauseButton()
        refreshTimeLabels()
    }
    
    func refreshTimeLabels(){
        self.lastLabel.text = formatTimeInterval(TimeInterval(self.progressSlider.value))
        self.restLabel.text = formatTimeInterval(TimeInterval(self.progressSlider.maximumValue - self.progressSlider.value))
    }
    
    func refreshPlayPauseButton(){
        var playButtonImageName: String = ""
        switch AudioPlayer.sharedInstance.state {
        case .play:
            playButtonImageName = "ic_pause_asphalt.png"
            
        case .pause, .stop:
            playButtonImageName = "ic_play_asphalt.png"
            
        }
        
        playPauseButton.setImage(UIImage(named: playButtonImageName), for: UIControlState())
    }
    
    func tick(){
        self.progressSlider.setValue(Float(AudioPlayer.sharedInstance.currentTime), animated: true)
        refreshTimeLabels()
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.truncatingRemainder(dividingBy: 60.0))
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        
        let minutes = Int(interval / 60.0)
        let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        
        return "\(minutesString):\(secondsString)"
    }
    
    @IBAction func PlayeBtn(_ sender: AnyObject) {

        switch AudioPlayer.sharedInstance.state {
        case .play:
            AudioPlayer.sharedInstance.pause()
            
        case .pause, .stop:
            AudioPlayer.sharedInstance.play()
        }
        refreshPlayPauseButton()
    }
}


