//
//  ProgressView.swift
//  Ertir
//
//  Created by Atakishiyev Orazdurdy on 2/25/15.
//  Copyright (c) 2015 Atakishiyev Orazdurdy. All rights reserved.
//

import Foundation
import UIKit

open class ProgressView {
    
    var containerView = UIView()
    var progressView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: ProgressView {
        struct Static {
            static let instance: ProgressView = ProgressView()
        }
        return Static.instance
    }
    
    func showProgressView(_ view: UIView) {
        //print(view.frame)
        containerView.frame = UIScreen.main.applicationFrame

        containerView.center = view.center
        
        containerView.backgroundColor = UIColor.clear//UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        progressView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressView.center = view.center
        progressView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator.center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        
        progressView.addSubview(activityIndicator)
        containerView.addSubview(progressView)
        view.addSubview(containerView)
        
        activityIndicator.startAnimating()
    }
    
    func hideProgressView() {
        activityIndicator.stopAnimating()
        containerView.removeFromSuperview()
    }
}
