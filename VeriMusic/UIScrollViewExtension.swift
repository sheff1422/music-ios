//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//
import Foundation
import UIKit

extension UIScrollView {

    fileprivate var pullToRefreshView: PullToRefreshView? {
        get {
            let pullToRefreshView = viewWithTag(PullToRefreshConst.tag)
            return pullToRefreshView as? PullToRefreshView
        }
    }

    func addPullToRefresh(_ refreshCompletion :@escaping (() -> ())) {
        let refreshViewFrame = CGRect(x: 0, y: -PullToRefreshConst.height, width: self.frame.size.width, height: PullToRefreshConst.height)
        let refreshView = PullToRefreshView(refreshCompletion: refreshCompletion, frame: refreshViewFrame)
        refreshView.tag = PullToRefreshConst.tag
        addSubview(refreshView)
    }

    func startPullToRefresh() {
        pullToRefreshView?.state = .refreshing
    }
    
    func stopPullToRefresh() {
        pullToRefreshView?.state = .normal
    }
    
    // If you want to PullToRefreshView fixed top potision, Please call this function in scrollViewDidScroll
    func fixedPullToRefreshViewForDidScroll() {
        if self.contentOffset.y < -PullToRefreshConst.height {
            if var frame = pullToRefreshView?.frame {
                frame.origin.y = self.contentOffset.y
                pullToRefreshView?.frame = frame
            }
        } else {
            if var frame = pullToRefreshView?.frame {
                frame.origin.y = -PullToRefreshConst.height
                pullToRefreshView?.frame = frame
            }
        }
    }
}
