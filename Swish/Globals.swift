//
//  Globals.swift
//  Swish
//
//  Created by Neil Natekar on 4/3/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class Globals{
    static let instance = Globals()
    
    var games: [NetworkGame] = []
    var selfPeerID: MCPeerID?
}
