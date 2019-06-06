//
//  OptionsController.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class OptionsController: UIViewController {    
    @IBOutlet weak var GameStart: UIButton!
    @IBOutlet weak var gamesTableContainer: UIView!
    @IBOutlet weak var gameRoomsLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        gamesTableContainer.isHidden = Globals.instance.isHosting
        GameStart.isHidden = (!Globals.instance.isHosting && Globals.instance.isMulti) // if
        // multiplayer and player is joiner, hide start button
        // temporary until we finish this view controller
        gameRoomsLabel.isHidden = Globals.instance.isHosting
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame"{
            let vc = segue.destination as! ViewController
            vc.multipeerSession = Globals.instance.session
        }
    }
    @IBAction func backButtonClicked(_ sender: Any) {
        self.dismiss(animated: true){
            if(Globals.instance.isHosting){
                Globals.instance.session?.advert.stopAdvertisingPeer()
            }
            else{
                Globals.instance.session?.browser.stopBrowsingForPeers()
                Globals.instance.games = []

            }
        }
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toGame", sender: Any?.self)
        }
    }
}
