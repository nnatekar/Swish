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
    @IBOutlet weak var welcomeStackView: UIStackView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nameStackView: UIStackView!
    @IBOutlet weak var handleField: UITextField!
    @IBOutlet weak var logo: UIView!
    @IBOutlet weak var swish: UIView!
    
    override func viewDidLoad() {
        initStyles()

        let handle = Cache.shared.object(forKey: "handle")
        print(handle as? String ?? "NULL")
        if handle != nil {
            handleField.text = handle as? String
        } else {
            let randomHandle = "ReadyPlayer" + String(arc4random()%500)
            Cache.shared.set(randomHandle, forKey: "handle")
            handleField.text = randomHandle
        }
    }
    
    @IBAction func playClicked(_ sender: Any){
        self.welcomeStackView.isHidden = true
        self.gameTypeStackView.isHidden = false
        backButton.isHidden = false
        logo.isHidden = true
        swish.isHidden = true
    }
    
    @IBAction func profileClicked(_ sender: Any) {
        self.welcomeStackView.isHidden = true
        self.nameStackView.isHidden = false
        backButton.isHidden = false
        logo.isHidden = true
        swish.isHidden = true
    }
    
    
    @IBAction func doneTyping(_ sender: UITextField) {
        if !handleField.text!.contains("ReadyPlayer") {
            Cache.shared.set(handleField.text, forKey: "handle")
        }
        sender.resignFirstResponder()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        if gameTypeStackView.isHidden == false {
            self.gameTypeStackView.isHidden = true
            self.welcomeStackView.isHidden = false
            self.backButton.isHidden = true
            logo.isHidden = false
            swish.isHidden = false
        } // currently on the game stack (single/multi) view, go back to welcome
        else if multiplayerStackView.isHidden == false {
            self.gameTypeStackView.isHidden = false
            self.multiplayerStackView.isHidden = true
            Globals.instance.isMulti = false
        } // currently on multiplayer stack view, go back to game stack
        else if nameStackView.isHidden == false {
            self.nameStackView.isHidden = true
            self.welcomeStackView.isHidden = false
            self.backButton.isHidden = true
            self.logo.isHidden = false
            self.swish.isHidden = false
        } // currently on name stack view, go back to welcome
    }
    
    @IBAction func multiplayerClicked(_ sender: Any) {
        self.backButton.isHidden = false
        self.gameTypeStackView.isHidden = true
        self.multiplayerStackView.isHidden = false
        Globals.instance.isMulti = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "hostGame"){
            Globals.instance.isHosting = true
        }
        
        initStyles()
        
        let handle = Cache.shared.object(forKey: "handle")
        Globals.instance.selfPeerID = MCPeerID(displayName: handle as! String)
        
    }
    
    func initStyles(){
        gameTypeStackView.isHidden = true
        multiplayerStackView.isHidden = true
        nameStackView.isHidden = true
        backButton.isHidden = true
        welcomeStackView.isHidden = false
        logo.isHidden = false
        swish.isHidden = false
    }
}

