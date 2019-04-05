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
        // TODO: FIGURE OUT HOW TO CHANGE RECEIVEDDATAHANDLER
        let session = MultipeerSession(peerID: Globals.instance.selfPeerID!, host: game.host)
        session.browser.invitePeer(game.host, to: session.session, withContext: nil, timeout: 10)
        guard let parent = parent as? OptionsController else { fatalError(" gamesTable unexpected parent") }
        // TODO: segue to viewcontroller, set the game session
    }
}

extension GamesTableController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Globals.instance.games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
}
