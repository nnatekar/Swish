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
    @IBOutlet weak var handleField: UITextField!
    @IBOutlet weak var gamesTableContainer: UIView!
    var session: MultipeerSession?
    override func viewDidLoad() {
        if(Globals.instance.isHosting){
            session = MultipeerSession(hostPeerID: Globals.instance.selfPeerID!)
        }
        else{
            session = MultipeerSession(selfPeerID: Globals.instance.selfPeerID!)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame"{
            let vc = segue.destination as! ViewController
            vc.isMultiplayer = true
            vc.selfHandle = Globals.instance.selfPeerID
        }
    }
    @IBAction func startButtonClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "toGame", sender: Any?.self)
    }
}
