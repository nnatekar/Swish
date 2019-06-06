//
//  MultipeerConnectivity.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//
import ARKit
import MultipeerConnectivity

protocol browserDelegate: class{
    func gameBrowser(_ browser: MCNearbyServiceBrowser, _ session: MCSession, sawGames: [NetworkGame])
    
    func removeGame(peerID: MCPeerID)
}

/**
  Custom multipeer class that handles peer-to-peer advertising and browsing.
 */
class MultipeerSession: NSObject{
    private let maxPeers: Int = kMCSessionMaximumNumberOfPeers - 1
    static let serviceType = "ar-multi-swish"
    private let peerID : MCPeerID!
    
    /// Currently active multipeer session.
    var session: MCSession!
    /// Current player's advertiser (used by hosts).
    var advert: MCNearbyServiceAdvertiser!
    /// Current player's browser (used by peers).
    var browser: MCNearbyServiceBrowser!
    /// A list of peers connected to this session.
    var connectedPeers: [MCPeerID]
    /// Function to handle some received data.
    var dataHandler: ((Data, MCPeerID) -> Void)?
    /// Function to handle world map and create a hoop.
    var basketSyncHandler: ((ARWorldMap, MCPeerID) -> Void)?
    weak var delegate: browserDelegate?
    
    /**
      Initializes a multipeer connection with a browser (used for peers).
    */
    init(selfPeerID: MCPeerID){
        self.connectedPeers = []
        self.peerID = selfPeerID
        super.init()
        
        // creates a new session to run multiplayer on
        session = MCSession(peer: self.peerID)
        session.delegate = self
        
        // start browsing for peers who are hosting
        startBrowsing(peerID: self.peerID)
    }
    
    /**
     Initializes a multipeer connection with a advertiser (used for hosts).
     */
    init(hostPeerID: MCPeerID){
        self.connectedPeers = []
        self.peerID = hostPeerID
        super.init()
        session = MCSession(peer: self.peerID)
        session.delegate = self
        
        // start advertising to peers who want to join games
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
    
    /**
      Sends data to all peers in connectedPeers.
     
     - parameters:
        - data: Data to send to all peers.
        - completion: Function to call after successfully sending data to all peers. Can be nil.
    */
    func sendToAllPeers(_ data: Data, completion: () -> Void){
        do{
            try session.send(data, toPeers: connectedPeers, with: .reliable)
            completion()
        } catch{
            print("Error: Could not send data to peers: \(error.localizedDescription)")
        }
    }
    
    func sendToPeer(_ data: Data, id: MCPeerID){
        do{
            try session.send(data, toPeers: [id], with: .reliable)
        } catch {
            print("Error: Could not send data to peers: \(error.localizedDescription)")
        }
    }
}


extension MultipeerSession: MCSessionDelegate{
    // state of a nearby peer changed; 2 states:
    // MCSessionState.connected = user accepted invite and is connected to session
    // MCSessionState.notConnected = user declined invite/connection failed/disconnected
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // someone disconnected, remove them from the list
        /*
        if(state == .notConnected && connectedPeers.count > 0){
            for i in 0...connectedPeers.count{

                if connectedPeers[i] == peerID{
                    connectedPeers.remove(at: i)
                }
            }
        } // big problem
         */
    }
    
    // received Data object from a peer
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do{
            // If the data received was a world map, call the basketsynchandler to sync the maps and create a basket.
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                basketSyncHandler!(worldMap, peerID)
                return
            }
        }
        catch{
        }
        
        do{
            // If the data received was an MCPeerID, need to append it to the list of connected peers.
            if let peer = try NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data) {
                if(peer.displayName != Globals.instance.selfPeerID!.displayName){
                    self.connectedPeers.append(peer)
                }
                return
            }
        }
        catch{
        }
        
        dataHandler?(data, peerID)
    }
    
    // Nearby peer opens bytestream connection to the local peer(user).
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    // Local peer(user) began receiving resource from nearby peer.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    // Local peer(user) finished receiving resource from nearby peer.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate{
    // Called when invitation to join session is received from peer.
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        // Add the peer who asked to join the session to list of connected peers.
        connectedPeers.append(peerID)
        Globals.instance.scores[peerID] = 0
        invitationHandler(true, session)
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate{
    // Nearby peer was found.
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        let game = NetworkGame(host: peerID, session: session, locationId: 0)
        
        // Found a game host, append the game to the global list.
        Globals.instance.games.append(game)
        Globals.instance.scores[peerID] = 0
        
        // Call the delegate browser to modify the table.
        self.delegate?.gameBrowser(browser, session, sawGames: Globals.instance.games)
        
    }
    
    // Nearby peer was lost.
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("User \(peerID) disconnected.")
        self.delegate?.removeGame(peerID: peerID)
    }
}
