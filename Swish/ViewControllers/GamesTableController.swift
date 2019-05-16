//
//  GamesTableControlle.swift
//  Swish
//
//  Created by Neil Natekar on 4/3/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class GamesTableController: UIViewController{
    @IBOutlet weak var gamesTableView: UITableView!
    @IBOutlet weak var playersTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    var browser: MCNearbyServiceBrowser?
    var multSession: MultipeerSession?{
        didSet{
        }
    }
    
    override func viewDidLoad() {
        gamesTableView.delegate = self
        gamesTableView.dataSource = self
        if(Globals.instance.isHosting){
            Globals.instance.session = MultipeerSession(hostPeerID: Globals.instance.selfPeerID!)
        }
        else{
            Globals.instance.session = MultipeerSession(selfPeerID: Globals.instance.selfPeerID!)
            gamesTableView.isHidden = true
            playersTableView.isHidden = false
        }
        multSession = Globals.instance.session
        multSession?.delegate = self
    }
    
    // TEMPORARY, REMOVE LATER
    func dataHandler(_ data: Data, from peer: MCPeerID) {
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        backButton.isHidden = true
        Globals.instance.session = MultipeerSession(selfPeerID: Globals.instance.selfPeerID!)
        gamesTableView.isHidden = true
        playersTableView.isHidden = false
        multSession = Globals.instance.session
        multSession?.delegate = self
    }
}

extension GamesTableController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView == gamesTableView){
            tableView.deselectRow(at: indexPath, animated: true)
            let game = Globals.instance.games[indexPath.row]
            // join the selected game
            self.browser!.invitePeer(game.host, to: game.session, withContext: nil, timeout: 10)
            // TODO: segue to viewcontroller, set the game session
            gamesTableView.isHidden = true
            playersTableView.isHidden = false
            backButton.isHidden = false
        }
    }
}

extension GamesTableController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(tableView == gamesTableView){
            return Globals.instance.games.count
        }
        else{
            return Globals.instance.session?.connectedPeers?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView == gamesTableView){
            let cell = tableView.dequeueReusableCell(withIdentifier: "gamesCell", for: indexPath)
            let game = Globals.instance.games[indexPath.row]
            cell.textLabel?.text = game.host.displayName
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "gamesCell", for: indexPath)
            let player = Globals.instance.session?.connectedPeers?[indexPath.row]
            cell.textLabel?.text = player?.displayName
            return cell
        }
    }
}

extension GamesTableController: browserDelegate{
    func gameBrowser(_ browser: MCNearbyServiceBrowser, _ session: MCSession, sawGames: [NetworkGame]) {
        self.browser = browser
        Globals.instance.games = sawGames
        
        gamesTableView.reloadData()
    }
}
