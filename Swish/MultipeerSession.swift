//
//  MultipeerConnectivity.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import MultipeerConnectivity

class MultipeerSession: NSObject{
    static let serviceType = "ar-multi-swish"
    
    private let peerID : MCPeerID!
    private var session: MCSession!
    private var advert: MCAdvertiserAssistant!
    private var browser: MCNearbyServiceBrowser!
    private var browserView: MCBrowserViewController!
    
    private let dataHandler: (Data, MCPeerID) -> Void
    
    init(peerID: MCPeerID, receivedDataHandler: @escaping (Data, MCPeerID) -> Void){
        self.peerID = peerID
        dataHandler = receivedDataHandler
        
        super.init()
        
        // creates a new session to run multiplayer on
        session = MCSession(peer: self.peerID)
        session.delegate = self
        
        // lets nearby users know you are looking for a session
        advert = MCAdvertiserAssistant(serviceType: MultipeerSession.serviceType, discoveryInfo: nil, session: session)
        advert.delegate = self
        advert.start()
        
        // searches for nearby users willing to join your session & sends invitations
        browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: MultipeerSession.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        
        // need to segue or present the view when required
        browserView = MCBrowserViewController(browser: browser, session: session)
        
        // TODO: Assign game's view conroller as browserview's delegate
        //browserView.delegate = ViewController
    }
    
    // returns list of all connected peers when called
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
    
    func sendToAllPeers(_ data: Data){
        do{
            // unreliable sends data right away, so it's critical for games
            try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
        } catch{
            print("Error: Could not send data to peers: \(error.localizedDescription)")
        }
    }
}


extension MultipeerSession: MCSessionDelegate{
    // state of a nearby peer changed; 2 states:
    // MCSessionState.connected = user accepted invite and is connected to session
    // MCSessionState.notConnected = user declined invite/connection failed/disconnected
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    // received Data object from a peer
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        dataHandler(data, peerID)
    }
    
    // nearby peer opens bytestream connection to the local peer(user)
    // stream = local endpoint for bytestream
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    // local peer(user) began receiving resource from nearby peer
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    // local peer(user) finished receiving resource from nearby peer
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}

extension MultipeerSession: MCAdvertiserAssistantDelegate{
    
    // called after user received and interacted with invitation to a session
    func advertiserAssistantDidDismissInvitation(_ advertiserAssistant: MCAdvertiserAssistant) {
        
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate{
    // nearby peer was found
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        //invite the found peer to the session
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        
    }
    
    // nearby peer was lost
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        // TODO: make UI to display that user disconnected
        print("User \(peerID) disconnected.")
    }
}
