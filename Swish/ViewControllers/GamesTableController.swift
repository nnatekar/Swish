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
    @IBOutlet weak var tableView: UITableView!
    var browser: MCNearbyServiceBrowser?
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // TEMPORARY, REMOVE LATER
    func dataHandler(_ data: Data, from peer: MCPeerID) {
    }
}

extension GamesTableController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let game = Globals.instance.games[indexPath.row]
        // join the selected game
        self.browser!.invitePeer(game.host, to: game.session, withContext: nil, timeout: 10)
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
    func gameBrowser(_ browser: MCNearbyServiceBrowser, _ session: MCSession, sawGames: [NetworkGame]) {
        print("smd")
        self.browser = browser
        Globals.instance.games = sawGames
        
        tableView.reloadData()
    }
}
