//
//  ImageLoader.swift
//  Ertir
//
//  Created by Atakishiyev Orazdurdy on 2/18/15.
//  Copyright (c) 2015 Atakishiyev Orazdurdy. All rights reserved.
//

import UIKit

class ImageLoader {
    
    var cache = NSCache<AnyObject, AnyObject>()
    
    class var sharedLoader : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    func imageForUrl(_ urlString: String, completionHandler:@escaping (_ image: UIImage?, _ url: String) -> ()) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {()in
            var data: Data? = self.cache.object(forKey: urlString as AnyObject) as? Data
            
            if let goodData = data {
                let image = UIImage(data: goodData)
                DispatchQueue.main.async(execute: {() in
                    completionHandler(image, urlString)
                })
                return
            }
            let downloadTask: URLSessionTask = URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: { (data, response, error) in
                if (error != nil) {
                    completionHandler(nil, urlString)
                    return
                }

                if data != nil {
                    let image = UIImage(data: data!)
                    self.cache.setObject(data as AnyObject, forKey: urlString as AnyObject)

                    DispatchQueue.main.async {
                        completionHandler(image, urlString)
                    }
                    return
                }
            })
//            var downloadTask: URLSessionDataTask = URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: ({(data: Data!, response: URLResponse!, error: NSError!) -> Void in
//                if (error != nil) {
//                    completionHandler(nil, urlString)
//                    return
//                }
//                
//                if data != nil {
//                    let image = UIImage(data: data)
//                    self.cache.setObject(data as AnyObject, forKey: urlString as AnyObject)
//                    
//                    DispatchQueue.main.async {
//                        completionHandler(image, urlString)
//                    }
//                    return
//                }
//                
//                })
            downloadTask.resume()
        })
        
    }
}
