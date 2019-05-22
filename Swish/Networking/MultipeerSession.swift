//
//  MultipeerConnectivity.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//
import ARKit
import MultipeerConnectivity

protocol browserDelegate: class{
    func gameBrowser(_ browser: MCNearbyServiceBrowser, _ session: MCSession, sawGames: [NetworkGame])
}

class MultipeerSession: NSObject{
    private let maxPeers: Int = kMCSessionMaximumNumberOfPeers - 1
    static let serviceType = "ar-multi-swish"
    
    private let peerID : MCPeerID!
    var session: MCSession!
    private var advert: MCNearbyServiceAdvertiser!
    var browser: MCNearbyServiceBrowser!
    
    var dataHandler: ((Data, MCPeerID) -> Void)?
    var basketSyncHandler: ((ARWorldMap, MCPeerID) -> Void)?
    weak var delegate: browserDelegate?
    
    init(selfPeerID: MCPeerID){
        self.connectedPeers = []
        self.peerID = selfPeerID
        super.init()
        // creates a new session to run multiplayer on
        session = MCSession(peer: self.peerID)
        session.delegate = self
        startBrowsing(peerID: self.peerID)
        // TODO: Assign game's view conroller as browserview's delegate
        //browserView.delegate = ViewController
    }
    
    init(hostPeerID: MCPeerID){
        self.connectedPeers = []
        self.peerID = hostPeerID
        super.init()
        session = MCSession(peer: self.peerID)
        session.delegate = self
        startAdvertising(peerID: self.peerID)
    }
    
    // player will start looking for hosts
    func startAdvertising(peerID: MCPeerID){
        // lets nearby users know you are looking for a session
        advert = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: MultipeerSession.serviceType)
        advert.delegate = self
        advert.startAdvertisingPeer()
    }
    
    // host will start looking for others to join session
    func startBrowsing(peerID: MCPeerID){
        // searches for nearby users willing to join your session & sends invitations
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: MultipeerSession.serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    // returns list of all connected peers when called
//    var connectedPeers: [MCPeerID]? {
//        return session?.connectedPeers
//    }
    var connectedPeers: [MCPeerID]
    
    func sendToAllPeers(_ data: Data){
        do{
            try session.send(data, toPeers: connectedPeers, with: .reliable)
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
        do{
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                basketSyncHandler!(worldMap, peerID)
            }
        }
        catch{
        }
        dataHandler!(data, peerID)
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

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate{
    // called when invitation to join session is received from peer
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // AUTOMATICALLY SETTING TO ACCEPT INVITE FOR NOW
        connectedPeers.append(peerID)
        invitationHandler(true, session)
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate{
    // nearby peer was found
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let game = NetworkGame(host: peerID, session: session, locationId: 0)
        Globals.instance.games.append(game)
<<<<<<< HEAD
=======
        connectedPeers.append(peerID)
>>>>>>> can send balls but buggy if players are too far away
        self.delegate?.gameBrowser(browser, session, sawGames: Globals.instance.games)
        //invite the found peer to the session
        //browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        
    }
    
    // nearby peer was lost
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        // TODO: make UI to display that user disconnected
        print("User \(peerID) disconnected.")
    }
}
