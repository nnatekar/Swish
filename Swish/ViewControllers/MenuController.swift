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
    
    override func viewDidLoad() {
        gameTypeStackView.isHidden = true
        multiplayerStackView.isHidden = true
        nameStackView.isHidden = true
        backButton.isHidden = true

        let handle = Cache.shared.object(forKey: "handle" as AnyObject)
        print(handle as? String ?? "NULL")
        if handle != nil {
            handleField.text = handle as? String
        } else {
            let randomHandle = "ReadyPlayer" + String(arc4random())
            Cache.shared.setObject("randomHandle" as AnyObject, forKey: "handle" as AnyObject)
            handleField.text = randomHandle
        }
    }
    
    @IBAction func playClicked(_ sender: Any){
        self.welcomeStackView.isHidden = true
        self.gameTypeStackView.isHidden = false
        backButton.isHidden = false
    }
    
    @IBAction func profileClicked(_ sender: Any) {
        self.welcomeStackView.isHidden = true
        self.nameStackView.isHidden = false
        backButton.isHidden = false
        
//        if(!handleField.text!.isEmpty){
            //performSegue(withIdentifier: "toOptions", sender: nil)
//        }
//        else{
//            msg.isHidden = false
//            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (nil) in
//                self.msg.isHidden = true
//            }
//        }
    }
    
    
    @IBAction func doneTyping(_ sender: UITextField) {
        if !handleField.text!.contains("ReadyPlayer") {
            Cache.shared.setObject(handleField.text as AnyObject, forKey: "handle" as AnyObject)
        }
        sender.resignFirstResponder()
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        if gameTypeStackView.isHidden == false {
            self.gameTypeStackView.isHidden = true
            self.welcomeStackView.isHidden = false
            self.backButton.isHidden = true
        } // currently on the game stack view, go back to welcome
        else if multiplayerStackView.isHidden == false {
            self.gameTypeStackView.isHidden = false
            self.multiplayerStackView.isHidden = true
        } // currently on multiplayer stack view, go back to game stack
        else if nameStackView.isHidden == false {
            self.nameStackView.isHidden = true
            self.welcomeStackView.isHidden = false
            self.backButton.isHidden = true
        } // currently on name stack view, go back to welcome
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

        let handle = Cache.shared.object(forKey: "handle" as AnyObject)
        Globals.instance.selfPeerID = MCPeerID(displayName: handle as! String)
    }
}

