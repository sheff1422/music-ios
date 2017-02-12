//
//  APIController.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

struct Config {
    
    static let VK_SERVER = "https://api.vk.com/"
    static let VK_AUDIO_SEARCH = VK_SERVER + "method/audio.search"
    static let ACCESS_TOKEN =  "e9dbafe947e48136f15bbaf1184095282f53bb146441910421e180b46fa6cf6cf8c37f7de3f525d2c121d"
    static let GET_TOKEN = "http://alashov.com/music/app/get_token.php"
}

func stringFromTimeInterval(_ interval: Int) -> String{
    let ti = NSInteger(interval)
    let seconds: NSInteger = ti % 60
    let minutes: NSInteger = (ti / 60) % 60
    let hours: NSInteger = (ti/3600)
    if hours > 0 {
        return NSString(format: "%02ld:%02ld:%02ld", hours, minutes, seconds) as String
    }
    return NSString(format: "%02ld:%02ld", minutes, seconds) as String
}

func getCountMusic(_ count: Int) -> Int{
    switch(count){
        case 0:
        return 30
        case 1: return 50
        case 2: return 100
        case 3: return 200
        case 4: return 300
        default: break
    }
    return 10
}

func getAudioFileDurationFromName(_ filename: String) -> String {
    let documentsPathh = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let audioPathh = documentsPathh+"/Audio"
    let audioFileURL = URL(fileURLWithPath:audioPathh+"/\(filename)")
    
    let audioAsset = AVURLAsset(url: audioFileURL, options: nil)
    let audioDuration = audioAsset.duration;
    let audioDurationSeconds = Int(CMTimeGetSeconds(audioDuration))
    
    return "\(stringFromTimeInterval(audioDurationSeconds))"
}

func getDownloadedAudioFiles() -> NSArray {
    
    let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] 
    do {
        // Get the directory contents urls (including subfolders urls)
        let directoryUrls = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
        let mp3Files = directoryUrls.map(){ $0.pathExtension }.filter(){ $0 == "mp3" }
        
        var mp3FilesAVURL = [PlaylistItem]()
        
        for mp3 in mp3Files {
            mp3FilesAVURL.append(getAudioAsseUrlForFilename(mp3))
        }
        
        return mp3FilesAVURL as NSArray
        
    } catch let error as NSError {
        return []
        print(error.localizedDescription)
    }
}

func getAudioAsseUrlForFilename(_ audioFile: String) -> PlaylistItem {
    let documentsPathh = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let audioFileURL = URL(fileURLWithPath:documentsPathh + "/\(audioFile)")
    
    let audioAsset = PlaylistItem(url: audioFileURL)
    
    return audioAsset
}

@objc
protocol APIControllerProtocol {
    func didReceiveAPIResults(_ results: NSDictionary, indexPath: IndexPath)
    @objc optional func result(_ status: String, error_msg: String, error_code: Int, captcha_sid: String, captcha_img: String)
}

class APIController {
    
    var delegate: APIControllerProtocol
    
    init(delegate: APIControllerProtocol) {
        self.delegate = delegate
    }
    
    func clientRequest(_ path: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = URL(string: path)
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: {data, response, error -> Void in
            if let json = self.CheckResponse(data as AnyObject){
                self.delegate.didReceiveAPIResults(json, indexPath: IndexPath())
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if(error != nil) {
                // If there is an error in the web request, print it to the console
                print(error!.localizedDescription)
            }
        })
        task.resume()
    }
    
    func getToken(_ path: String) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = URL(string: path)
        let session = URLSession.shared
        let task = session.dataTask(with: url!, completionHandler: {data, response, error -> Void in
            guard let unwrappedData = data else {
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: unwrappedData, options: [.mutableLeaves]) as? NSDictionary
                guard let unwrappedJson = json else {
                    return
                }
                let newToken: String = unwrappedJson["vkToken"] as! String
                let downloadEnabled: Int = unwrappedJson["downloadEnabled"] as! Int
                
                UserDefaults.standard.set(downloadEnabled, forKey: "downloadEnabled")
                UserDefaults.standard.set(newToken, forKey: "vkToken")
                self.delegate.didReceiveAPIResults(["status":"ok"], indexPath: IndexPath())
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
 
            }
            catch {
                print(error.localizedDescription)

            }
        })
        task.resume()
    }
    
    func CheckResponse(_ responseObject: AnyObject) -> NSDictionary? {
        if let data = responseObject as? Data {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [.mutableLeaves]) as? NSDictionary
                //print(json)
                //    open class func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions = []) throws -> Any
                guard let jsonUnwrapped = json else {
                    return nil
                }
                if (jsonUnwrapped["response"] as? NSArray != nil){
                    return json
                }
                else if let error = jsonUnwrapped["error"] as? NSDictionary {
                    
                    if let error_code = error["error_code"] as? Int {
                        if let error_msg = error["error_msg"] as? String {
                            print("\(error_code)  \(error_msg)")

                            switch error_code {
                                case 14:
                                    let captcha_sid = error["captcha_sid"] as? String
                                    let captcha_img = error["captcha_img"] as? String
                                    self.delegate.result!("error", error_msg: error_msg, error_code: error_code, captcha_sid: captcha_sid!, captcha_img: captcha_img!)
                                    print("\(captcha_sid!)  \(captcha_img!)")
                                case 5:
                                    self.delegate.result!("error", error_msg: error_msg, error_code: error_code, captcha_sid: "", captcha_img: "")
                                case 6:
                                    self.delegate.result!("error", error_msg: error_msg, error_code: error_code, captcha_sid: "", captcha_img: "")
                                case 10:
                                    self.delegate.result!("error", error_msg: error_msg, error_code: error_code, captcha_sid: "", captcha_img: "")
                                default:break
                            }
                        }
                    }
                    
                }
                }catch {
                    print(error.localizedDescription)
                }
            }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        return nil
    }
    
    func searchVKFor(_ searchTerm: String) {
        
        let VKSearchTerm = searchTerm.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.caseInsensitive, range: nil)
        
        if let escapedSearchTerm = VKSearchTerm.addingPercentEscapes(using: String.Encoding.utf8) {
            
            var sort = UserDefaults.standard.integer(forKey: "sort")
            var count = getCountMusic(UserDefaults.standard.integer(forKey: "count"))
            let performer_only_bool = UserDefaults.standard.bool(forKey: "performer_only") ? 1 : 0
            if count < 0 {
                UserDefaults.standard.set(30, forKey: "count")
                count = 30
            }
            if sort < 0 {
                UserDefaults.standard.set(2, forKey: "sort")
                sort = 2
            }
            
            if let vkToken: String = UserDefaults.standard.value(forKey: "vkToken") as? String {
                let urlPath = "\(Config.VK_AUDIO_SEARCH)?access_token=\(vkToken)&q=\(escapedSearchTerm)&sort=\(sort)&count=\(count)&performer_only=\(performer_only_bool)"
                clientRequest(urlPath)
            }else{
                let urlPath = "\(Config.VK_AUDIO_SEARCH)?access_token=\(Config.ACCESS_TOKEN)&q=\(escapedSearchTerm)&sort=\(sort)&count=\(count)&performer_only=\(performer_only_bool)"
                clientRequest(urlPath)
            }
        }
    }
    
    func audioInfo(_ audio: TrackList, indexPath: IndexPath){
        
        let session = URLSession.shared
        let task = session.dataTask(with: audio.url, completionHandler: {data, response, error -> Void in
            if let httpResponse = response as? HTTPURLResponse {
                //print(httpResponse)
                if let contentType = httpResponse.allHeaderFields["Content-Length"] as? String {
                    //print(contentType)
                    self.delegate.didReceiveAPIResults(["length": contentType, "title": audio.title], indexPath: indexPath)
                }
            }
            if(error != nil) {
                print(error!.localizedDescription)
            }
        })
        task.resume()
    }
    
    func captchaWrite(_ captcha_sid: String, captcha_key: String){
        if let vkToken: String = UserDefaults.standard.value(forKey: "vkToken") as? String {
            let url = "\(Config.VK_AUDIO_SEARCH)?access_token=\(vkToken)&captcha_sid=\(captcha_sid)&captcha_key=\(captcha_key)"
            clientRequest(url)
        }else{
            let url = "\(Config.VK_AUDIO_SEARCH)?access_token=\(Config.ACCESS_TOKEN)&captcha_sid=\(captcha_sid)&captcha_key=\(captcha_key)"
            clientRequest(url)
        }
    }
    
}
