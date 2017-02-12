//
//  TrackList.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation

open class TrackList {
    
    var aid: Int
    var owner_id: Int
    var artist: String
    var title: String
    var duration: Int
    var lyrics_id: Int
    var genre: Int
    var remoteUrl: URL
    
    init (aid: Int, owner_id: Int, artist: String, title: String, duration: Int, url: String, lyrics_id: Int, genre: Int, remoteUrl: URL){
        self.aid = aid
        self.owner_id = owner_id
        self.artist = artist
        self.title = title
        self.duration = duration
        self.lyrics_id = lyrics_id
        self.genre = genre
        self.remoteUrl = remoteUrl
    }
    
    var url: URL {
        get{
            return self.remoteUrl
        }
    }
    
    class func TrackListWithJSON(_ trackListResult: NSArray) -> [TrackList] {
        
        var trackList = [TrackList]()
        var trackListResults = trackListResult as! [[String:AnyObject]]
        if trackListResult.count > 0 {
            for index in 1 ..< trackListResults.count {
                let aid  = trackListResults[index]["aid"] as! Int
                let owner_id = trackListResults[index]["owner_id"] as! Int
                let artist = trackListResults[index]["artist"] as? String ?? ""
                let title = trackListResults[index]["title"] as? String ?? "untitled"
                let duration = trackListResults[index]["duration"] as! Int
                let url = trackListResults[index]["url"] as! String
                let lyrics_id = trackListResults[index]["lyrics_id"] as? Int ?? 0
                let genre = trackListResults[index]["genre"] as? Int ?? 0
                let urlString = trackListResults[index]["url"] as! String
                let remoteURL = URL(string: urlString)!
                
                var newTrack = TrackList(aid: aid, owner_id: owner_id, artist: artist, title: title, duration: duration, url: url, lyrics_id: lyrics_id, genre: genre, remoteUrl: remoteURL)
                trackList.append(newTrack)
            }
            
        }
        
        return trackList
    }
    
}

class DownloadedFiles {
    
    var title: String
    var duration: String
    
    init(title: String, duration: String){
        self.title = title
        self.duration = duration
    }
    
    class func DownloadedFilesWithArray(_ files: NSArray) -> [DownloadedFiles] {
        var fileList = [DownloadedFiles]()
        for file in files {
            let title = file as! String
            let duration = getAudioFileDurationFromName(title)
            
            var newFile = DownloadedFiles(title: title, duration: duration)
            fileList.append(newFile)
        }
        
        return fileList
    }
}











