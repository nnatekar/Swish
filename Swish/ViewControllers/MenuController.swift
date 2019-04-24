//
//  File.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit
import MultipeerConnectivity

class MenuController : UIViewController {
    
    @IBOutlet weak var multiplayerStackView: UIStackView!
    @IBOutlet weak var gameTypeStackView: UIStackView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var handleField: UITextField!
    @IBOutlet weak var msg: UILabel!
    
    override func viewDidLoad() {
        multiplayerStackView.isHidden = true
        backButton.isHidden = true
    }
    @IBAction func startClicked(_ sender: Any) {
        if(!handleField.text!.isEmpty){
            performSegue(withIdentifier: "toOptions", sender: nil)
        }
        else{
            msg.isHidden = false
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (nil) in
                self.msg.isHidden = true
            }
        }
    }
    
    @IBAction func doneTyping(_ sender: UITextField) {
        sender.resignFirstResponder()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.gameTypeStackView.isHidden = false
        self.multiplayerStackView.isHidden = true
        self.backButton.isHidden = true
    }
    
    @IBAction func multiplayerClicked(_ sender: Any) {
        self.backButton.isHidden = false
        self.gameTypeStackView.isHidden = true
        self.multiplayerStackView.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "hostGame"){
            Globals.instance.isHosting = true
        }
        
        Globals.instance.selfPeerID = MCPeerID(displayName: handleField.text!)
    }
}

