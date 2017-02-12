//
//  DownloadedFilesVC.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/17/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

class DownloadedFilesVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet fileprivate var controlBar: PlayerControlBar?
    @IBOutlet fileprivate var volumeView: MPVolumeView?
    @IBOutlet fileprivate var blurAlbumArtworkImageView: UIImageView?
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var shuffleBtn: MKButton!
    @IBOutlet weak var repeatBtn: MKButton!
    
    var downloadedFiles = [PlaylistItem]()
    var kCellIdentifier = "PlaylistTableViewCell"
    
    fileprivate var player: MusicPlayer?
    
    var searcher = UISearchController()
    var searching = false
    var originalSectionData = [PlaylistItem]()
    var currentPlayList = [PlaylistItem]()
    var refreshControl:UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.blurAlbumArtworkImageView?.image = UIImage(named: "black.jpg")
        self.repeatBtn.setImage(UIImage(named: "repeat"), for: UIControlState())
        player = MusicPlayer()
        player?.delegate = self
        controlBar?.player = player
  
        volumeView?.showsVolumeSlider = true
        volumeView?.showsRouteButton = false
        volumeView?.sizeToFit()
        self.getPlayList()
        
        self.tableView.separatorColor = UIColor.Colors.Grey.withAlphaComponent(0.3)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.searchBar.sizeToFit()
        let textFieldInsideSearchBar = self.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.white
        repeatPlay()
        self.view.backgroundColor = UIColor.clear
        self.tableView.addPullToRefresh({ [weak self] in
            self?.getPlayList()
            self?.tableView.stopPullToRefresh()
            })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        becomeFirstResponder()
        self.tableView.setContentOffset(
            CGPoint(x: 0, y: 44),
            animated:true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
        player?.pause()
    }
    
    //MARK: - events received from phone
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else {
            return
        }
        player?.remoteControlReceivedWithEvent(event)

        switch event.subtype {
        case .remoteControlPlay:
            player?.play()
        case .remoteControlPause:
            player?.pause()
        default:
            print("received sub type \(event.subtype) Ignoring")
        }

    }
    
    override var canBecomeFirstResponder : Bool {
        //allow this instance to receive remote control events
        return true
    }
    
    func getPlayList(){
        player?.playlist.removeAll(keepingCapacity: false)
        let items: [PlaylistItem] = getDownloadedAudioFiles() as! [PlaylistItem]
        self.originalSectionData = items
        self.currentPlayList = items
        player?.playlist.append(contentsOf:items)
        self.tableView.reloadData()
        self.tableView.setContentOffset(
            CGPoint(x: 0, y: 44),
            animated:true)
    }
    
    func shufflePlaylist() {
        player?.shuffle()
        tableView?.reloadData()
    }
    
    func repeatPlay(){
        var repeatPlay: Bool = false
        if let bool = UserDefaults.standard.value(forKey: "repeat") as? Bool {
            repeatPlay = bool
        }
        if (repeatPlay) {
            repeatBtn.backgroundColor = UIColor.Colors.BlueGrey
        }else{
            repeatBtn.backgroundColor = UIColor.clear
        }
    }
    
    @IBAction func repeatAction(_ sender: UIButton) {
        var repeatPlay: Bool = false
        if let bool = UserDefaults.standard.value(forKey: "repeat") as? Bool {
            repeatPlay = !bool
        }
        
        if (repeatPlay) {
            repeatBtn.backgroundColor = UIColor.Colors.BlueGrey
        }else{
            repeatBtn.backgroundColor = UIColor.clear
        }
        UserDefaults.standard.setValue(repeatPlay, forKey: "repeat")
    }
    
    @IBAction func shuffleAction(_ sender: UIButton) {
        shufflePlaylist()
    }
   
}

extension DownloadedFilesVC: MusicPlayerDelegate {
    func player(_ playlistPlayer: MusicPlayer, didChangeCurrentPlaylistItem playlistItem: PlaylistItem?) {
        if (playlistItem?.artwork != nil){
            blurAlbumArtworkImageView?.image = playlistItem?.artwork
        }

        var title: String = ""
        var artist: String = ""
        if(playlistItem?.title != nil && playlistItem?.artist != nil && playlistItem?.title != "untitled"){
            title = playlistItem!.title!
            artist = playlistItem!.artist!
        }else{
            let filename: AnyObject? = playlistItem!.asset.value(forKey: "URL") as AnyObject?
            if let name = filename?.lastPathComponent.components(separatedBy: " - "){
                title = name[1]
                artist = name[0]
            }
        }
        var artImage = UIImage(named: "imgTrack")
        if playlistItem?.artwork != nil{
            artImage = playlistItem?.artwork
        }
        let artwork = MPMediaItemArtwork(image: artImage!)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: title as String , MPMediaItemPropertyArtist: artist as String, MPMediaItemPropertyArtwork: artwork]
        
        tableView?.reloadData()
    }
}

extension DownloadedFilesVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let player = self.player {
            return player.playlist.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistTableViewCell") as! PlaylistTableViewCell
        
        let item = player?.playlist[indexPath.row]
        
        if(player?.playlist[indexPath.row].artwork != nil){
            cell.albumArtworkImageView?.image = player?.playlist[indexPath.row].artwork
        }else{
            cell.albumArtworkImageView?.image = UIImage(named: "imgTrack")
        }
        if item?.title != nil && item?.title != "untitled" {
            cell.titleLabel?.text = item?.title
        }else{
            let filename: AnyObject? = self.player?.playlist[indexPath.row].asset.value(forKey: "URL") as AnyObject?
            if let name = filename?.lastPathComponent.components(separatedBy: " - "){
                cell.titleLabel?.text = name[1]
                cell.artistAndAlbumNameLabel?.text = name[0]
            }
        }
        if item?.artist != nil && item?.albumName != nil {
            cell.artistAndAlbumNameLabel?.text = "\(item!.artist!) | \(item!.albumName!)"
        }
        
        if player?.currentItem == item {
            cell.titleLabel?.textColor = UIColor.gray.withAlphaComponent(0.5)
            cell.artistAndAlbumNameLabel?.textColor = UIColor.gray.withAlphaComponent(0.5)
        } else {
            cell.titleLabel?.textColor = UIColor.white
            cell.artistAndAlbumNameLabel?.textColor = UIColor.white
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player?.setCurrentItemFromIndex(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAtIndexPath indexPath: IndexPath) -> [AnyObject]?  {
        
        let deleteSongAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "delete", handler: { (action:UITableViewRowAction!, indexPath:IndexPath!) -> Void in
            let filename: AnyObject? = self.player?.playlist[indexPath.row].asset.value(forKey: "URL") as AnyObject?
            DownloadManager.sharedInstance.removeAudio(filename!.lastPathComponent)
            self.player?.playlist.remove(at: indexPath.row)
    
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
        })
        return [deleteSongAction]
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
}

extension DownloadedFilesVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let target = searchText
        
        if target == "" {
            player?.playlist.removeAll(keepingCapacity: false)
            player?.playlist.append(contentsOf:self.originalSectionData)
            self.tableView.reloadData()
            return
        }
        self.currentPlayList = self.originalSectionData.filter({( file : PlaylistItem) -> Bool in
                var stringMatch = file.title!.range(of: target, options:
                    NSString.CompareOptions.caseInsensitive)
                return (stringMatch != nil)
        })
        player?.playlist.removeAll(keepingCapacity: false)
        player?.playlist.append(contentsOf:self.currentPlayList)
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
}

extension DownloadedFilesVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}
