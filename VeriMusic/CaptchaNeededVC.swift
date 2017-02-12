//
//  CaptchaNeededVC.swift
//  vkMusic
//
//  Created by Atakishiyev Orazdurdy on 5/11/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import UIKit

class CaptchaNeededVC: UIViewController {
    
    @IBOutlet weak var newCaptchaImgBtn: UIButton!
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var captchaImg: UIImageView!
    @IBOutlet weak var captchaCodeFromImg: UITextField!
    var captchaImgUrl = ""
    var captcha_sid = ""
    var api : APIController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.newCaptchaImgBtn.titleLabel?.text = NSLocalizedString("reload", comment: "Reload")
        self.sendBtn.titleLabel?.text = NSLocalizedString("send", comment: "Send")
        let escpaedurl = captchaImgUrl.addingPercentEscapes(using: String.Encoding.utf8)
        ImageLoader.sharedLoader.imageForUrl(escpaedurl!, completionHandler: {(image: UIImage?, url: String) in
            if image != nil {
                self.captchaImg.image = image
                self.newCaptchaImgBtn.isEnabled = true
                self.sendBtn.isEnabled = true
            }
        })
    }
    
    @IBAction func SendCaptcha(_ sender: UIButton) {
        api = APIController(delegate: self)
        api!.captchaWrite(captcha_sid, captcha_key: captchaCodeFromImg.text!)
    }
    
    @IBAction func newCaptchaImg(_ sender: AnyObject) {
        let escpaedurl = captchaImgUrl.addingPercentEscapes(using: String.Encoding.utf8)
        ImageLoader.sharedLoader.imageForUrl(escpaedurl!, completionHandler: {(image: UIImage?, url: String) in
            if image != nil {
                self.captchaImg.image = image
                self.newCaptchaImgBtn.isEnabled = true
                self.sendBtn.isEnabled = true
            }
        })
    }
}

extension CaptchaNeededVC: APIControllerProtocol {
    
    func didReceiveAPIResults(_ results: NSDictionary, indexPath: IndexPath) {
        self.dismiss(animated: true, completion: nil)
    }
}
