//
//  GamesTableControlle.swift
//  Swish
//
//  Created by Neil Natekar on 4/3/19.
//

import UIKit
import MultipeerConnectivity

class GamesTableController: UIViewController{
    @IBOutlet weak var tableView: UITableView!
    var browser: MCNearbyServiceBrowser?
    var multSession: MultipeerSession?{
        didSet{
        }
    }
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
        
        // If we are hosting,
        if(Globals.instance.isHosting){
            Globals.instance.session = MultipeerSession(hostPeerID: Globals.instance.selfPeerID!)
        }
        else{
            Globals.instance.session = MultipeerSession(selfPeerID: Globals.instance.selfPeerID!)
        }
        multSession = Globals.instance.session
        multSession?.delegate = self
    }
    
    func dataHandler(_ data: Data, from peer: MCPeerID) {
    }
}

extension GamesTableController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let game = Globals.instance.games[indexPath.row]
        multSession?.connectedPeers.append(game.host)
        // join the selected game
        browser?.stopBrowsingForPeers()
        self.browser!.invitePeer(game.host, to: game.session, withContext: nil, timeout: 10)
        
        self.parent!.performSegue(withIdentifier: "toGame", sender: Any?.self)
        if(!Globals.instance.connectionSuccessful){
            Globals.instance.games.remove(at: indexPath.row)
            tableView.reloadData()
        }
        // TODO: segue to viewcontroller, set the game session
    }
}

extension GamesTableController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Globals.instance.games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gamesCell", for: indexPath)
        let game = Globals.instance.games[indexPath.row]
        cell.textLabel?.text = game.host.displayName
        return cell
    }
}

extension GamesTableController: browserDelegate{
    func removeGame(peerID: MCPeerID) {
        var index = -1
        var i = 0
        for g in Globals.instance.games{
            if(peerID == g.host){
                index = i
            }
            i += 1
        }
        Globals.instance.games.remove(at: index)
        tableView.reloadData()
    }
    
    func gameBrowser(_ browser: MCNearbyServiceBrowser, _ session: MCSession, sawGames: [NetworkGame]) {
        self.browser = browser
        Globals.instance.games = sawGames
        
        tableView.reloadData()
    }
}
