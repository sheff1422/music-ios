//
//  CacheHandler.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/12/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation
import UIKit

public protocol VFCacheHandlerDelegate: class {
    func downloadManager(_ result: String)
}

open class VFCacheHandler : NSObject, URLSessionDownloadDelegate {
    
    fileprivate var backgroundSession: Foundation.URLSession?
    fileprivate var dictionary = Dictionary<URL, URL>()
    
    internal var delegates: [VFCacheHandlerDelegate] = []
    
    override init() {
        super.init()
        backgroundSession = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }
    open class var sharedInstance: VFCacheHandler {
        struct Singleton {
            static let instance = VFCacheHandler()
        }
        
        return Singleton.instance
    }
   /* class var sharedInstance : VFCacheHandler {
        struct Static {
            static let instance : VFCacheHandler = VFCacheHandler()
        }
        
        return Static.instance
    }*/
    
    func downloadAudio(_ audio: TrackList){
        let session = Foundation.URLSession(configuration: URLSessionConfiguration.default,
            delegate: self,
            delegateQueue: nil)
        let downloadTask = session.downloadTask(with: audio.url as URL, completionHandler: { (location: URL!, response: URLResponse!, error: NSError!) -> Void in
            switch (location, error){
            case (.some, .none):
                var filename = "\(audio.artist) - \(audio.title).mp3"
                switch self.saveTemporaryAudioFromLocation(location, filename: filename) {
                case .some(let newLocation):
                    print("New file location \(newLocation)")
                    self.sync {
                        for delegate in self.delegates {
                            delegate.downloadManager("--------------------\n")
                        }
                    }
                    self.dictionary[audio.url as URL] = newLocation
                case .none:
                    return
                }
                
            case (.none, .none):
                print("Empty location")
                
            case (.none, .some):
                print("Error \(error.description)")
                
            default:
                return
            }
        } as! (URL?, URLResponse?, Error?) -> Void)
        
        downloadTask.resume()
    }
    /*
    func removeAudio(audio: TrackList){
        switch localURLForAudio(audio){
        case .Some(let localURL):
            var error: NSError?
            if !NSFileManager.defaultManager().removeItemAtURL(localURL, error: &error) {
                print("Error while removing audio from cache: \(error?.localizedDescription)")
            } else {
                self.dictionary.removeValueForKey(audio.remoteURL)
            }
            
        default:
            return
        }
    }*/
    
    func removeAudio(_ audioFilename: String){
        var documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        let audioPath = documentsPath + "/Audio"
        let audioFileURL = URL(fileURLWithPath:audioPath + "/\(audioFilename)")
        var error: NSError?
        do { try FileManager.default.removeItem(at: audioFileURL)
        } catch {
            print("Error while removing audio from cache: \(error.localizedDescription)")
        }
        
    }
    
    func localURLForAudio(_ audio: TrackList) -> URL?{
        return self.dictionary[audio.remoteUrl as URL]
    }
    
    //MARK: - NSURLSession Delegate methods
    
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?){
        
    }
    
    open func URLSession(_ session: Foundation.URLSession, didReceiveChallenge challenge: URLAuthenticationChallenge, completionHandler: (Foundation.URLSession.AuthChallengeDisposition, URLCredential?) -> Void){
        completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
    }
    
    open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession){
        
    }
    
    func saveTemporaryAudioFromLocation(_ location: URL, filename: String) -> URL?{
        var documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        let audioPath = documentsPath + "/Audio"
        let audioFileURL = URL(fileURLWithPath:audioPath + "/\(filename)")
        
        var error: NSError?
        
        do {
            try FileManager.default.createDirectory(atPath:audioPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error while Audio folder creation: \(error.localizedDescription)")
            return nil
        }

        if FileManager.default.fileExists(atPath: audioFileURL.path) {
            print("File already exists!")
            return audioFileURL
        }
        do {
            try FileManager.default.copyItem(at: location, to: audioFileURL)
            return audioFileURL
        } catch {
            print("Error while temp audio file replacing: \(error.localizedDescription)")
            return nil
        }
    }
    
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL){
        
    }
    
    /* Sent periodically to notify the delegate of download progress. */
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64){
        
    }
    
    /* Sent when a download has been resumed. If a download failed with an
    * error, the -userInfo dictionary of the error will contain an
    * NSURLSessionDownloadTaskResumeData key, whose value is the resume
    * data.
    */
    open func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64){
        
    }
    internal let queue = DispatchQueue(label: "io.persson.DownloadManager", attributes: DispatchQueue.Attributes.concurrent)
    
    internal func sync(_ closure: () -> Void) {
        self.queue.sync(execute: closure)
    }
    
    internal func async(_ closure: @escaping () -> Void) {
        self.queue.async(execute: closure)
    }

}
extension VFCacheHandler {
    
    public func subscribe(_ delegate: VFCacheHandlerDelegate) {
        async {
            for (index, d) in self.delegates.enumerated() {
                if delegate === d {
                    return
                }
            }
            
            self.delegates.append(delegate)
        }
    }
    
    public func unsubscribe(_ delegate: VFCacheHandlerDelegate) {
        async {
            for (index, d) in self.delegates.enumerated() {
                if delegate === d {
                    self.delegates.remove(at: index)
                    return
                }
            }
        }
}
}
