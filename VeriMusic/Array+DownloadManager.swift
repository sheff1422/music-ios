//
//  Array+DownloadManager.swift
//  DownloadManager
//
//  Created by Atakishiyev Orazdurdy on 5/9/15.
//  Copyright (c) 2015 veriloft. All rights reserved.
//

import Foundation

extension Array {
    
    mutating func remove<U: Equatable>(_ object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerated() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                    break
                }
            }
        }
        
        if(index != nil) {
            self.remove(at: index!)
        }
    }
    
    mutating func remove<U: Equatable>(_ objects: [U]) {
        for object in objects {
            self.remove(object)
        }
    }
    
}
