//
//  DownloadManager.swift
//  DownloadManager
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation


public protocol DownloadManagerDelegate{
    func downloadManager(_ downloadManager: DownloadManager, downloadDidFail url: URL, error: NSError, indexPath: IndexPath)
    func downloadManager(_ downloadManager: DownloadManager, downloadDidStart url: URL, resumed: Bool, indexPath: IndexPath)
    func downloadManager(_ downloadManager: DownloadManager, downloadDidFinish url: URL, indexPath: IndexPath)
    func downloadManager(_ downloadManager: DownloadManager, downloadDidProgress url: URL, totalSize: UInt64, downloadedSize: UInt64, percentage: Double, averageDownloadSpeedInBytes: UInt64, timeRemaining: TimeInterval, indexPath: IndexPath)
    func equals(otherObject: DownloadManagerDelegate) -> Bool
}

func ==(left: DownloadManager.Download, right: DownloadManager.Download) -> Bool {
    return left.url == right.url
}

open class DownloadManager: NSObject, NSURLConnectionDataDelegate {
    
    internal let queue = DispatchQueue(label: "io.persson.DownloadManager", attributes: DispatchQueue.Attributes.concurrent)
    
    internal var delegates: [DownloadManagerDelegate] = []
    internal var downloads: [DownloadManager.Download] = []
    
    
    
    class Download: Equatable {
        
        let url:      URL
        let filePath: String
        
        let stream:     OutputStream
        let connection: NSURLConnection
        
        var totalSize: UInt64
        var downloadedSize: UInt64 = 0
        
        var indexPath: IndexPath
        
        // Variables used for calculating average download speed
        // The lower the interval (downloadSampleInterval) the higher the accuracy (fluctuations)
        
        internal let sampleInterval       = 0.25
        internal let sampledSecondsNeeded = 5.0
        
        internal lazy var sampledBytesTotal: Int = {
            return Int(ceil(self.sampledSecondsNeeded / self.sampleInterval))
            }()
        
        internal var samples: [UInt64] = []
        internal var sampleTimer: Timer?
        internal var lastAverageCalculated = Date()
        
        internal var bytesWritten = 0
        internal let queue = DispatchQueue(label: "dk.dr.radioapp.DownloadManager.SampleQueue", attributes: DispatchQueue.Attributes.concurrent)
        
        var averageDownloadSpeed: UInt64 = UInt64.max
        
        init(url: URL, filePath: String, totalSize: UInt64, connection: NSURLConnection, indexPath: IndexPath) {
            self.queue.setTarget(queue: DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background))
            
            self.url       = url
            self.filePath  = filePath
            self.totalSize = totalSize
            
            self.indexPath = indexPath
            
            do{
                let dict: NSDictionary = try FileManager.default.attributesOfItem(atPath: self.filePath) as NSDictionary
                self.downloadedSize = dict.fileSize()
            }catch {
                print(error.localizedDescription)
            }
            
            self.stream     = OutputStream(toFileAtPath: self.filePath, append: self.downloadedSize > 0)!
            self.connection = connection
            
            self.stream.schedule(in: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
            self.stream.open()
            
            self.sampleTimer?.invalidate()
            self.sampleTimer = Timer(interval: self.sampleInterval, repeats: true, pauseInBackground: true, block: { [weak self] () -> () in
                if let strongSelf = self {
                    strongSelf.queue.sync(execute: { () -> Void in
                        strongSelf.samples.append(UInt64(strongSelf.bytesWritten))
                        
                        let diff = strongSelf.samples.count - strongSelf.sampledBytesTotal
                        
                        if diff > 0 {
                            for i in (0...diff - 1) {
                                strongSelf.samples.remove(at: 0)
                            }
                        }
                        
                        strongSelf.bytesWritten = 0
                        
                        let now = Date()
                        
                        if now.timeIntervalSince(strongSelf.lastAverageCalculated) >= 5 && strongSelf.samples.count >= strongSelf.sampledBytesTotal {
                            var totalBytes: UInt64 = 0
                            
                            for sample in strongSelf.samples {
                                totalBytes += sample
                            }
                            
                            strongSelf.averageDownloadSpeed  = UInt64(round(Double(totalBytes) / strongSelf.sampledSecondsNeeded))
                            strongSelf.lastAverageCalculated = now
                        }
                    })
                }
                })
        }
        
        func write(_ data: Data) {
            let written = self.stream.write((data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), maxLength: data.count)
            
            if written > 0 {
                self.queue.async(execute: { () -> Void in
                    self.bytesWritten += written
                })
            }
        }
        
        func close() {
            self.sampleTimer?.invalidate()
            self.sampleTimer = nil
            
            self.stream.close()
        }
        
    }
    
}

// MARK: Static vars

extension DownloadManager {
    
    public class var sharedInstance: DownloadManager {
        struct Singleton {
            static let instance = DownloadManager()
        }
        
        return Singleton.instance
    }
    
}

// MARK: Internal methods

extension DownloadManager {
    
    internal func downloadForConnection(_ connection: NSURLConnection) -> Download? {
        var result: Download? = nil
        
        sync {
            for download in self.downloads {
                if download.connection == connection {
                    result = download
                    break
                }
            }
        }
        
        return result
    }
    
    internal func sync(_ closure: () -> Void) {
        self.queue.sync(execute: closure)
    }
    
    internal func async(_ closure: @escaping () -> Void) {
        self.queue.async(execute: closure)
    }
    
}

// MARK: Public methods

extension DownloadManager {

    public func subscribe(_ delegate: DownloadManagerDelegate) {
        async {
            for (index, d) in self.delegates.enumerated() {
                if delegate.equals(otherObject: d) {
                    return
                }
            }
            self.delegates.append(delegate)
        }
    }
    
    public func unsubscribe(_ delegate: DownloadManagerDelegate) {
        async {
            for (index, d) in self.delegates.enumerated() {
                if delegate.equals(otherObject: d) {
                    self.delegates.remove(at: index)
                    return
                }
            }
        }
    }
    
    public func isDownloading(_ url: URL) -> Bool {
        var result = false
        
        sync {
            for download in self.downloads {
                if download.url == url {
                    result = true
                    break
                }
            }
        }
        
        return result
    }
    
    public func download(_ currentAudio: TrackList, indexPath: IndexPath) -> Bool {
        let documentsPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString)//.stringByAppendingPathComponent("Audio")
        let path = documentsPath.appendingPathComponent("\(currentAudio.artist) - \(currentAudio.title).mp3")
        
        if self.isDownloading(currentAudio.url as URL) {
            return true
        }
    
        let request = NSMutableURLRequest(url: currentAudio.url as URL)
        
        do {
            let dict: NSDictionary = try FileManager.default.attributesOfItem(atPath:path) as NSDictionary
            request.addValue("bytes=\(dict.fileSize())-", forHTTPHeaderField: "Range")

        }catch {
            print(error.localizedDescription)
        }
        do {
            let dict: NSDictionary = try FileManager.default.attributesOfItem(atPath:path) as NSDictionary
            request.addValue("bytes=\(dict.fileSize())-", forHTTPHeaderField: "Range")

        } catch {
            print(error.localizedDescription)
        }
        
        if let connection = NSURLConnection(request: request as URLRequest, delegate: self, startImmediately: false) {
            sync {
                self.downloads.append(Download(url: currentAudio.url as URL, filePath: path, totalSize: 0, connection: connection, indexPath: indexPath))
            }
            
            connection.schedule(in: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
            connection.start()
            
            return true
        }
        
        return false
    }
    
    public func removeAudio(_ audioFilename: String){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        //let audioPath = documentsPath.stringByAppendingPathComponent("Audio")
        let audioFileURL = URL(fileURLWithPath:documentsPath + "/\(audioFilename)")
        do {
            try FileManager.default.removeItem(at:audioFileURL)
        }
        catch {
            print("Error while removing audio from cache: \(error.localizedDescription)")
        }
    }
    
    public func stopDownloading(_ url: URL) {
        sync {
            for download in self.downloads {
                if download.url == url {
                    download.connection.cancel()
                    download.close()
                    
                    self.downloads.remove(download)
                    
                    break
                }
            }
        }
    }
    
    func applicationWillTerminate() {
        sync {
            for download in self.downloads {
                download.connection.cancel()
                download.close()
            }
        }
    }
    
}

// MARK: Public methods

extension DownloadManager {
    
    public func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        if let download = self.downloadForConnection(connection) {
            let contentLength = response.expectedContentLength
            
            download.totalSize = contentLength == -1 ? 0 : UInt64(contentLength) + download.downloadedSize
            
            sync {
                for delegate in self.delegates {
                    delegate.downloadManager(self, downloadDidStart: download.url, resumed: download.totalSize > 0, indexPath: download.indexPath)
                }
            }
        }
    }
    
    public func connection(_ connection: NSURLConnection, didReceive data: Data) {
        if let download = self.downloadForConnection(connection) {
            var percentage: Double = 0
            var remaining: TimeInterval = TimeInterval.nan
            
            sync {
                download.write(data)
                download.downloadedSize += UInt64(data.count)
                
                if download.totalSize > 0 {
                    percentage = Double(download.downloadedSize) / Double(download.totalSize)
                    
                    if download.averageDownloadSpeed != UInt64.max {
                        if download.averageDownloadSpeed == 0 {
                            remaining = TimeInterval.infinity
                        } else {
                            remaining = TimeInterval((download.totalSize - download.downloadedSize) / download.averageDownloadSpeed)
                        }
                    }
                }
                
                for delegate in self.delegates {
                    delegate.downloadManager(
                        self,
                        downloadDidProgress:         download.url,
                        totalSize:                   download.totalSize,
                        downloadedSize:              download.downloadedSize,
                        percentage:                  percentage,
                        averageDownloadSpeedInBytes: download.averageDownloadSpeed,
                        timeRemaining:               remaining,
                        indexPath:                   download.indexPath
                    )
                }
            }
        }
    }
    
    public func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        if let download = self.downloadForConnection(connection) {
            sync {
                for delegate in self.delegates {
                    delegate.downloadManager(self, downloadDidFail: download.url, error: error as NSError, indexPath: download.indexPath)
                }
                
                download.close()
                
                self.downloads.remove(download)
            }
        }
    }
    
    public func connectionDidFinishLoading(_ connection: NSURLConnection) {
        if let download = self.downloadForConnection(connection) {
            sync {
                for delegate in self.delegates {
                    delegate.downloadManager(self, downloadDidFinish: download.url, indexPath: download.indexPath)
                }
                
                download.close()
                
                self.downloads.remove(download)
            }
        }
    }
}
