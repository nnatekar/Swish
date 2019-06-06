//
//  Globals.swift
//  Swish
//
//  Created by Neil Natekar on 4/3/19.
//

import Foundation
import MultipeerConnectivity

class Globals{
    static let instance = Globals()
    
    var games: [NetworkGame] = []
    var scores: [MCPeerID: Int] = [:]
    var selfPeerID: MCPeerID?
    var isHosting: Bool = false
    var isMulti: Bool = false
    var session: MultipeerSession?
}
