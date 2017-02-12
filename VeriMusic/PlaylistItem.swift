//
//  PlaylistItem.swift
//  music
//
//  Created by Atakishiyev Orazdurdy on 5/19/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

private var playlistItemImageCache: [String: UIImage] = [:]

extension MPMediaItem {
    
    func asPlaylistItem() -> PlaylistItem {
        let item = PlaylistItem(url: self.assetURL!)
        print(item)
        item.title = self.title
        item.artist = self.artist
        item.albumName = self.albumTitle
        
        var audioAsset = AVURLAsset(url: URL(string: self.assetURL!.path)!, options: nil)
        var audioDuration = audioAsset.duration;
        var audioDurationSeconds = Int(CMTimeGetSeconds(audioDuration))
        
        item.durationOfFile = stringFromTimeInterval(audioDurationSeconds)
        
        let cacheID = "\(item.artist!) | \(item.albumName!)"
        let kAlbumArtworkSize = CGSize(width: 256.0, height: 256.0)
        if let cached = playlistItemImageCache[cacheID] {
            item.artwork = cached
        } else if let artwork = self.artwork?.image(at: kAlbumArtworkSize) {
            playlistItemImageCache[cacheID] = artwork
            item.artwork = artwork
        }
        
        return item
    }
}

class PlaylistItem: AVPlayerItem {
    
    class func clearImageCache() {
        playlistItemImageCache.removeAll(keepingCapacity: false)
    }
    
    var durationOfFile: String = ""
    
    lazy var title: String? = {
        if let titleMetadataItem = AVMetadataItem.metadataItems(from: self.asset.commonMetadata, withKey: AVMetadataCommonKeyTitle, keySpace: AVMetadataKeySpaceCommon).first  {
            return titleMetadataItem.value as? String
        }
        return ""
        }()
    
    lazy var artist: String? = {
        if let artistMetadataItem = AVMetadataItem.metadataItems(from: self.asset.commonMetadata, withKey: AVMetadataCommonKeyArtist, keySpace: AVMetadataKeySpaceCommon).first  {
            return artistMetadataItem.value as? String
        }
        return nil
        }()
    
    lazy var albumName: String? = {
        if let albumNameMetadataItem = AVMetadataItem.metadataItems(from: self.asset.commonMetadata, withKey: AVMetadataCommonKeyAlbumName, keySpace: AVMetadataKeySpaceCommon).first  {
            return albumNameMetadataItem.value as? String
        }
        return nil
        }()
    
    lazy var artwork: UIImage? = {
        
        var cacheID: String = ""
        if self.artist != nil && self.albumName != nil {
            cacheID = "\(self.artist) | \(self.albumName)"
        }
        
        if let cached = playlistItemImageCache[cacheID] {
            return cached
        } else if let artworkMetadataItem = AVMetadataItem.metadataItems(from: self.asset.commonMetadata, withKey: AVMetadataCommonKeyArtwork, keySpace: AVMetadataKeySpaceCommon).first  {
            
            if let artworkMetadataDictionary = artworkMetadataItem.value as? [String: AnyObject] {
                if let artworkData = artworkMetadataDictionary["data"] as? NSData {
                    if let image = UIImage(data: artworkData as Data) {
                        playlistItemImageCache[cacheID] = image
                        return image
                    }
                }
            } else if let artworkData = artworkMetadataItem.value as? NSData {
                if let image = UIImage(data: artworkData as Data) {
                    playlistItemImageCache[cacheID] = image
                    return image
                }
            }
            
        }
        return nil
        }()
}
