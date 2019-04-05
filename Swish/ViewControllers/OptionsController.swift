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
    var isHosting: Bool = false
    @IBOutlet weak var gamesTableContainer: UIView!
    
    override func viewDidLoad() {
        if(isHosting){
            // need to create multipeer session and pass it to
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame"{
            let vc = segue.destination as! ViewController
            vc.isMultiplayer = true
            vc.selfHandle = MCPeerID(displayName: handleField.text!)
        }
    }
    @IBAction func startButtonClicked(_ sender: Any) {
        if(!handleField.text!.isEmpty){
            self.performSegue(withIdentifier: "toGame", sender: Any?.self)
        }
        
    }
}
