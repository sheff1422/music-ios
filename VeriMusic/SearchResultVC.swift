//
//  ViewController.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class SearchResultVC: UIViewController {

    let kCellIdentifier: String = "SearchResultCell"
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsItem: UIBarButtonItem!
   
    var timer: Foundation.Timer? = nil
    var api : APIController?
    var imageCache = [String : UIImage]()
    var trackList = [TrackList]()
    var cacheFileSize: NSCache<AnyObject, AnyObject>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        api = APIController(delegate: self)
        self.api?.getToken(Config.GET_TOKEN)
        
        settingsItem.title = NSLocalizedString("settings", comment: "Settings")
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        self.searchBar.delegate = self
        self.searchBar.searchBarStyle = UISearchBarStyle.minimal
        self.tableView.separatorColor = UIColor.Colors.Grey.withAlphaComponent(0.3)
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        GetTrackList("")
        
        self.tableView.addPullToRefresh({ [weak self] in
            self?.GetTrackList("")
            self?.tableView.stopPullToRefresh()
        })
        getDownloadedAudioFiles()
        DownloadManager.sharedInstance.subscribe(self)
        cacheFileSize = NSCache()

        let player = UIBarButtonItem(title: NSLocalizedString("player", comment: "Player"), style: .plain, target: self, action: #selector(SearchResultVC.seguePlayer(_:)))
        if let downloadEnabled = UserDefaults.standard.value(forKey: "downloadEnabled") as? Int {
            if downloadEnabled == 1 {
                self.navigationItem.rightBarButtonItem = player
            }
        }
    }

    deinit {
        DownloadManager.sharedInstance.unsubscribe(self)
    }
    
    func seguePlayer(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "PlayerVC", sender: nil)
    }
    
    func GetTrackList(_ searchText: String){
        let popular_songs = (UserDefaults.standard.bool(forKey: "popular_songs"))

        if popular_songs {
            //api = APIController(delegate: self)
            api!.searchVKFor(searchText)
        }else{
            if(searchText != ""){
              //  api = APIController(delegate: self)
                api!.searchVKFor(searchText)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPlayer" {
            if let blogActions = segue.destination as? PlayMusic {
                if let ppc = blogActions.popoverPresentationController {
                    ppc.delegate = self
                }
            }
        }
    }

    @IBAction func playBtnTapped(_ sender: UIButton) {
        
        let button = sender as UIButton
        let viewB = button.superview!
        let viewBack = viewB.superview
        let cell = viewBack?.superview as! SearchResultCell
        
        let indexPath = self.tableView.indexPath(for: cell)
        
        showPopover(indexPath!)
    }
    
    func showPopover(_ indexPath: IndexPath)
    {
        if let popoverVC = self.storyboard?.instantiateViewController(withIdentifier: "PlayMusic") as? PlayMusic
        {
            popoverVC.modalPresentationStyle = .popover
            popoverVC.trackList = self.trackList
            popoverVC.index = indexPath.row
            
            AudioPlayer.sharedInstance.currentAudio = trackList[indexPath.row]
            AudioPlayer.sharedInstance.play()
            ProgressView.shared.showProgressView(view)
            let popover = popoverVC.popoverPresentationController!
            popover.delegate = self
            var frame = UIScreen.main.applicationFrame
            popover.sourceView = view
            var rect = CGRect(x: 0 , y: frame.origin.y , width: frame.width, height: frame.height)
            popover.sourceRect = rect
            popover.permittedArrowDirections = [.up, .down]
            present(popoverVC, animated: true, completion: nil)
        }
    }
}

extension SearchResultVC: APIControllerProtocol {
    
    func didReceiveAPIResults(_ results: NSDictionary, indexPath: IndexPath) {
        if let resultsArr = results["response"] as? NSArray {
            //print(resultsArr)
            DispatchQueue.main.async(execute: {
                self.trackList = TrackList.TrackListWithJSON(resultsArr)
                self.tableView!.reloadData()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
        }
        if let length = results["length"] as? String {
            print(length)
            DispatchQueue.main.async(execute: {
                if (indexPath.row > 0){
                    self.cacheFileSize.setObject("\((length as NSString).doubleValue/1024)" as AnyObject, forKey: results["title"]! as AnyObject)
                    self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
                }
            })
        }
        if let status = results["status"] as? String {
            GetTrackList(self.searchBar.text!)
        }
    }
    
    func result(_ status: String, error_msg: String, error_code: Int, captcha_sid: String, captcha_img: String)
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if(error_code == 14){
            var captchaNeededVC = self.storyboard?.instantiateViewController(withIdentifier: "CaptchaNeededVC") as! CaptchaNeededVC
            captchaNeededVC.captchaImgUrl = captcha_img
            captchaNeededVC.captcha_sid = captcha_sid
            self.navigationController?.present(captchaNeededVC, animated: true, completion: nil)
        }
        
        if(error_code == 5){
            self.api?.getToken(Config.GET_TOKEN)
            GetTrackList("")
        }
        
        if(error_code == 6){
            self.GetTrackList("Fink")
        }
        
        if(error_code == 10){
            self.api?.getToken(Config.GET_TOKEN)
            GetTrackList("")
        }
        
    }
}

extension SearchResultVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        /*timer?.invalidate()
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("getHints:"), userInfo: searchText, repeats: false)*/
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.GetTrackList(searchBar.text!)
        self.searchBar.resignFirstResponder()
    }
    
    func getHints(_ timer: Foundation.Timer) {
        if ((timer.userInfo as AnyObject).length >= 3){
            self.GetTrackList(timer.userInfo! as! String)
            self.searchBar.resignFirstResponder()
        }
    }

}

extension SearchResultVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCell(withIdentifier: kCellIdentifier) as! SearchResultCell
        
        let track = self.trackList[indexPath.row]
        var title = track.title.replacingOccurrences(of:"amp;", with: "")
        var artist = track.artist.replacingOccurrences(of:"amp;", with: "")
        
        cell.title.text = "\(artist) - \(title)"
        cell.durationBtn.titleLabel?.text = stringFromTimeInterval(track.duration)
        cell.progressView.isHidden = true
        cell.size.isHidden = true
        var selectedBack = UIView();
        selectedBack.backgroundColor = UIColor(hex: 0x9E9E9E, alpha: 0.1)
        cell.selectedBackgroundView = selectedBack

        if let size: String = cacheFileSize.object(forKey: track.title as AnyObject) as? String {
            cell.size.isHidden = false
            cell.size.text = (NSString(format:"%.2f", (size as NSString).doubleValue/1024) as String) + " mb."
        }else{
            cell.size.text = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentAudio = trackList[indexPath.row]
        var title = currentAudio.title.replacingOccurrences(of:"amp;", with: "")
        var artist = currentAudio.artist.replacingOccurrences(of:"amp;", with: "")
        
        var cell = tableView.cellForRow(at: indexPath) as! SearchResultCell
        
        cell.selectedBackgroundView?.backgroundColor = UIColor(hex: 0x9E9E9E, alpha: 0.1)
        cell.viewBackDuration.backgroundColor = UIColor.Colors.BlueGrey.withAlphaComponent(0.7)
        DispatchQueue.main.async(execute: {
            if(self.cacheFileSize.object(forKey: currentAudio.title as AnyObject) == nil) {
                self.api?.audioInfo(currentAudio, indexPath: indexPath)
            }
        })
        

        let shareMenu = UIAlertController(title: "\(artist)", message: "\(title)", preferredStyle: .actionSheet)
        if let presentationController = shareMenu.popoverPresentationController {
            var selectedCell = tableView.cellForRow(at: indexPath)
            presentationController.sourceView = selectedCell?.contentView
            presentationController.sourceRect = selectedCell!.contentView.frame
        }
        
        let download = UIAlertAction(title: NSLocalizedString("download", comment: "Download"), style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            DownloadManager.sharedInstance.download(currentAudio, indexPath: indexPath)
        })
        let play = UIAlertAction(title: NSLocalizedString("play", comment: "Play button"), style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            self.showPopover(indexPath)
        })
        let share = UIAlertAction(title: NSLocalizedString("share", comment: "Share button"), style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            let textToShare = NSLocalizedString("advice", comment: "Hey! You should check up this music!")
            
            if let myWebsite = URL(string: "http://www.alashov.com/music/download.php?audio_id=\(currentAudio.owner_id)_\(currentAudio.aid)")
            {
                let objectsToShare = [textToShare, myWebsite] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                var selectedCell = tableView.cellForRow(at: indexPath)
                activityVC.popoverPresentationController!.sourceView = selectedCell?.contentView
                
                self.present(activityVC, animated: true, completion: nil)
            }
        })
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel", comment: "Cancel button"), style: UIAlertActionStyle.cancel, handler: nil)
        if let downloadEnabled = UserDefaults.standard.value(forKey: "downloadEnabled") as? Int {
            if downloadEnabled == 1 {
                shareMenu.addAction(download)
            }
        }
        
        shareMenu.addAction(play)
        shareMenu.addAction(share)
        shareMenu.addAction(cancelAction)

        self.present(shareMenu, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
}

extension SearchResultVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
}

extension SearchResultVC: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        AudioPlayer.sharedInstance.pause()
    }
}

extension SearchResultVC: DownloadManagerDelegate {
    func equals(otherObject: DownloadManagerDelegate) -> Bool {
        if let otherAsSelf = otherObject as? SearchResultVC {
            return otherAsSelf == self
        }
        return false
    }
    func downloadManager(_ downloadManager: DownloadManager, downloadDidFail url: URL, error: NSError, indexPath: IndexPath) {
        print("Failed to download: \(url.absoluteString)")
        let selectedCell = self.tableView.cellForRow(at: indexPath) as? SearchResultCell
        selectedCell?.progressView.isHidden = true
    }
    
    func downloadManager(_ downloadManager: DownloadManager, downloadDidStart url: URL, resumed: Bool, indexPath: IndexPath) {
        print("Started to download: \(url.absoluteString)")
    }
    
    func downloadManager(_ downloadManager: DownloadManager, downloadDidFinish url: URL, indexPath: IndexPath) {
        print("Finished downloading: \(url.absoluteString)")
        let selectedCell = self.tableView.cellForRow(at: indexPath) as? SearchResultCell
        selectedCell?.progressView.isHidden = true
    }
    
    func downloadManager(_ downloadManager: DownloadManager, downloadDidProgress url: URL, totalSize: UInt64, downloadedSize: UInt64, percentage: Double, averageDownloadSpeedInBytes: UInt64, timeRemaining: TimeInterval, indexPath: IndexPath) {
        //print("Downloading \(url.absoluteString) (Percentage: \(percentage))")
        let selectedCell = self.tableView.cellForRow(at: indexPath) as? SearchResultCell
        selectedCell?.progressView.isHidden = false
        selectedCell?.counter = Int(percentage * 100)
    }
}
