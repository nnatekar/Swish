//
//  NetworkGame.swift
//  Swish
//
//  Created by Jugal Jain on 4/2/19.
//
import MultipeerConnectivity

// Game on the network.
struct NetworkGame: Hashable {
    var session: MCSession
    var host: MCPeerID
    private var locationId: Int
    
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
    
    init(host: MCPeerID, session: MCSession, locationId: Int = 0) {
        self.host = host
        self.session = session
        self.locationId = locationId
    }
    
}
