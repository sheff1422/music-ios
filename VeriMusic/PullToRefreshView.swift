//
//  PullToRefreshConst.swift
//  PullToRefreshSwift
//
//  Created by Yuji Hato on 12/11/14.
//
import UIKit

open class PullToRefreshView: UIView {
    enum PullToRefreshState {
        case normal
        case pulling
        case refreshing
    }
    
    // MARK: Variables
    let contentOffsetKeyPath = "contentOffset"
    var kvoContext = ""

    fileprivate var arrow: UIImageView!
    fileprivate var indicator: UIActivityIndicatorView!
    fileprivate var scrollViewBounces: Bool = false
    fileprivate var scrollViewInsets: UIEdgeInsets = UIEdgeInsets.zero
    fileprivate var previousOffset: CGFloat = 0
    fileprivate var refreshCompletion: (() -> ()) = {}
    
    var state: PullToRefreshState = PullToRefreshState.normal {
        didSet {
            switch self.state {
            case .normal:
                stopAnimating()
            case .refreshing:
                startAnimating()
            default:
                break
            }
        }
    }
    
    // MARK: UIView
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    convenience init(refreshCompletion :@escaping (() -> ()), frame: CGRect) {
        self.init(frame: frame)
        self.refreshCompletion = refreshCompletion;
        
        self.arrow = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        self.arrow.autoresizingMask = [UIViewAutoresizing.flexibleLeftMargin ,  UIViewAutoresizing.flexibleRightMargin]
        self.arrow.image = UIImage(named: PullToRefreshConst.imageName)
        self.addSubview(arrow)
        
        self.indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        self.indicator.bounds = self.arrow.bounds
        self.indicator.autoresizingMask = self.arrow.autoresizingMask
        self.indicator.hidesWhenStopped = true
        self.addSubview(indicator)
        
        self.autoresizingMask = UIViewAutoresizing.flexibleWidth
       // self.backgroundColor = PullToRefreshConst.backgroundColor
    }
   
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.arrow.center = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
        self.indicator.center = self.arrow.center
    }
    
    open override func willMove(toSuperview superView: UIView!) {
        superview?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
        if (superView != nil && superView is UIScrollView) {
            superView.addObserver(self, forKeyPath: contentOffsetKeyPath, options: .initial, context: &kvoContext)
            scrollViewBounces = (superView as! UIScrollView).bounces
            scrollViewInsets = (superView as! UIScrollView).contentInset
        }
    }
    
    deinit {
        let scrollView = superview as? UIScrollView
        scrollView?.removeObserver(self, forKeyPath: contentOffsetKeyPath, context: &kvoContext)
    }
    
    // MARK: KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if (context == &kvoContext && keyPath == contentOffsetKeyPath) {
            if let scrollView = object as? UIScrollView {
                
                // Debug
                //print(scrollView.contentOffset.y)
                
                let offsetWithoutInsets = self.previousOffset + self.scrollViewInsets.top
                if (offsetWithoutInsets < -self.frame.size.height) {
                    
                    // pulling or refreshing
                    if (scrollView.isDragging == false && self.state != .refreshing) {
                        self.state = .refreshing
                    } else if (self.state != .refreshing) {
                        self.arrowRotation()
                        self.state = .pulling
                    }
                } else if (self.state != .refreshing && offsetWithoutInsets < 0) {
                    // normal
                    self.arrowRotationBack()
                    self.state == .normal
                }
                self.previousOffset = scrollView.contentOffset.y
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // MARK: private
    
    fileprivate func startAnimating() {
        self.indicator.startAnimating()
        self.arrow.isHidden = true
        
        var scrollView = superview as! UIScrollView
        var insets = scrollView.contentInset
        insets.top += self.frame.size.height
        scrollView.contentOffset.y = self.previousOffset
        scrollView.bounces = false
        UIView.animate(withDuration: PullToRefreshConst.duration, delay: 0, options:[], animations: {
            scrollView.contentInset = insets
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: -insets.top)
        }, completion: {finished in
                self.state = .normal
                self.refreshCompletion()
        })
    }
    
    fileprivate func stopAnimating() {
        self.indicator.stopAnimating()
        self.arrow.transform = CGAffineTransform.identity
        self.arrow.isHidden = false
        
        let scrollView = superview as! UIScrollView
        scrollView.bounces = self.scrollViewBounces
        UIView.animate(withDuration: PullToRefreshConst.duration, animations: { () -> Void in
            scrollView.contentInset = self.scrollViewInsets
        }, completion: { (Bool) -> Void in

        }) 
    }
    
    fileprivate func arrowRotation() {
        UIView.animate(withDuration:0.2, delay: 0, options:[], animations: {
            // -0.0000001 for the rotation direction control
            self.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI-0.0000001))
            }, completion: nil)
    }
    
    fileprivate func arrowRotationBack() {
       /* UIView.animateWithDuration(0.2, delay: 0, options: nil, animations: {
            self.arrow.transform = CGAffineTransformIdentity
            }, completion: nil)*/
    }
}
