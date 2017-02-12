//
//  Timer.swift
//  DownloadManager
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import UIKit

class Timer: NSObject {
    
    internal var block, timerBlock: (()->())?
    internal var timer: DispatchSource?
    
    internal var fireDate: Date!
    internal var interval: Double = 1.0
    
    internal var repeats: Bool = false
    internal var pauseInBackground: Bool = false
    
    internal var didPauseInBackground = false
    
    init(interval: Double = 1.0, repeats: Bool = false, pauseInBackground: Bool = true, block: @escaping () -> ()) {
        super.init()
        self.block = block
        self.interval = interval
        self.repeats = repeats
        self.pauseInBackground = pauseInBackground
        
        self.start()
    }
    
    func start() {
        self.invalidate()
        
        
        self.timerBlock = { [weak self] in
            if let strongSelf = self {
                if (strongSelf.block != nil) {
                    strongSelf.block!()
                }
                
                strongSelf.invalidate()
                
                if !strongSelf.repeats {
                    strongSelf.fireDate = nil
                } else {
                    strongSelf.start()
                }
            }
        }
        
        var start = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        
        self.timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as? DispatchSource
        self.timer?.scheduleRepeating(deadline: .now() + interval, interval: Double(NSEC_PER_SEC), leeway: .seconds(1))
        self.timer?.setEventHandler(handler: self.timerBlock!)
        self.timer!.resume()
        
        self.fireDate = Date().addingTimeInterval(interval)
        
        NotificationCenter.default.addObserver(self, selector: #selector(Timer.resume), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(Timer.pause), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    func resume() {
        if let date = self.fireDate {
            if Date().compare(self.fireDate) != .orderedAscending {
                self.timerBlock!()
                didPauseInBackground = false
                return
            } else if didPauseInBackground {
                didPauseInBackground = false
                
                let interval = self.fireDate.timeIntervalSince(Date())
                
                var start = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                
                self.timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as? DispatchSource
                self.timer?.scheduleRepeating(deadline: .now() + interval, interval: Double(NSEC_PER_SEC), leeway: .milliseconds(100))
                self.timer?.setEventHandler(handler: self.timerBlock!)
                self.timer!.resume()
            }
        }
    }
    
    func pause() {
        if self.pauseInBackground, let timer = self.timer {
            didPauseInBackground = true
            timer.cancel()
            self.timer = nil
        }
    }
    
    func stop() {
        self.invalidate()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.invalidate()
    }
    
    func invalidate() {
        if let timer = self.timer {
            timer.cancel()
            self.fireDate = nil
            self.timer    = nil
        }
    }
    
}
