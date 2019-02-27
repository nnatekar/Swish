//
//  MultipeerConnectivity.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import MultipeerConnectivity

class MultipeerSession: NSObject{
    private let peerID : MCPeerID!
    private var session: MCSession!
    private var advert: MCAdvertiserAssistant!
    private var browser: MCNearbyServiceBrowser!
    private var browserView: MCBrowserViewController!
    
    private let dataHandler: (Data, MCPeerID) -> Void
    
    init(peerID: String, receivedDataHandler: @escaping (Data, MCPeerID) -> Void){
        self.peerID = MCPeerID(displayName: peerID)
        dataHandler = receivedDataHandler
        
        super.init()
        
        session = MCSession(peer: self.peerID)
        session.delegate = self
        
        
    }
}


extension MultipeerSession: MCSessionDelegate{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        <#code#>
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        dataHandler(data, peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        <#code#>
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        <#code#>
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
    
}
