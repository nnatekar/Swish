//
//  Cache.swift
//  Swish
//
//  Created by Tran Nguyen on 4/30/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation

// singleton cache
class Cache: NSCache<AnyObject, AnyObject> {
    static let shared = NSCache<AnyObject, AnyObject>();
    private override init() {
        super.init()
    }
}
