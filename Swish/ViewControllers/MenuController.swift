//
//  File.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
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
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var logo: UIView!
    @IBOutlet weak var swish: UIView!
    @IBOutlet weak var gifView: UIImageView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var instructionsLabel2: UILabel!
    @IBOutlet weak var tutButton: UIButton!
    
    override func viewDidLoad() {
        initStyles()

        // Create a cached username for player which can then be changed.
        let handle = Cache.shared.object(forKey: "handle")
        print(handle as? String ?? "NULL")
        Globals.instance.isMulti = false;
        if handle != nil {
            handleField.text = handle as? String
        } else {
            let randomHandle = "ReadyPlayer" + String(arc4random()%500)
            Cache.shared.set(randomHandle, forKey: "handle")
            handleField.text = randomHandle
        }
        tutorialView.isHidden = true
        tutButton.isHidden = false
        gifView.loadGif(asset: "arworldscancropped")
        instructionsLabel.numberOfLines = 0
        instructionsLabel.lineBreakMode = .byWordWrapping
        instructionsLabel.text = "\nInstructions for Multiplayer Setup \n\n1) You can choose between Hosting and Joining a game when you click Play > Multiplayer. There can be multiple Joiners but only ONE host \n\n2) If hosting, scan the \"World Map\" by slowly moving your device across your surroundings as shown below. This shows up on screen as tiny yellow spots displayed on flat horizontal surfaces \n"
        
        instructionsLabel2.numberOfLines = 0
        instructionsLabel2.lineBreakMode = .byWordWrapping
        instructionsLabel2.text = "\n3) The message on the screen will change from Not Available > Limited > Extending > Mapped. When the message becomes \"Mapped\" the World is sufficiently scanned, and the basket can be placed \n\n4) Place the basket by tapping on any yellow dot that you see on your screen. You may have to look around to find where the basket has been placed. REMEMBER the location where you tapped! \n\n5) Once the basket is placed, the host can now click the \"Send World Map\" button at the bottom of the screen \n\n6) If playing as a Joiner, the first step is the same as for hosts, which is to scan your surroundings \n\n7) Once the host sends the World Map, a message saying \"Received World Map From Peers\" will show up on the Joiner's screen.\n\n8) Keep scanning the world until the message on screen says \"Mapped\" \n\n9) Wait for some time for the basket to show up on the screen. If it does not show up, stand where the Host is and tap the exact location where the Host did \n\n10) Once all players have a basket on screen, they can all click the \"Ready\" button at the bottom. Once all the players in the session have clicked \"Ready\" the game will start.\n"
    }
    
    // The play button was clicked.
    @IBAction func playClicked(_ sender: Any){
        self.welcomeStackView.isHidden = true
        self.gameTypeStackView.isHidden = false
        backButton.isHidden = false
        logo.isHidden = true
        swish.isHidden = true
        tutButton.isHidden = true
    }
    
    @IBAction func onTutorialClick(_ sender: Any) {
        tutorialView.isHidden = false
        
    }
    // The profile button was clicked.
    @IBAction func profileClicked(_ sender: Any) {
        self.welcomeStackView.isHidden = true
        self.nameStackView.isHidden = false
        backButton.isHidden = false
        logo.isHidden = true
        swish.isHidden = true
        tutButton.isHidden = true
    }
    
    // User finished typing in their handle, store it in the cache.
    @IBAction func doneTyping(_ sender: UITextField) {
        if !handleField.text!.contains("ReadyPlayer") {
            Cache.shared.set(handleField.text, forKey: "handle")
        }
        sender.resignFirstResponder()
    }
    
    @IBAction func backInstructionClicked(_ sender: Any) {
        tutorialView.isHidden = true
    }
    // User pressed back after pressing play or profile.
    @IBAction func backButtonClicked(_ sender: Any) {
        if gameTypeStackView.isHidden == false {
            self.gameTypeStackView.isHidden = true
            self.welcomeStackView.isHidden = false
            self.backButton.isHidden = true
            logo.isHidden = false
            swish.isHidden = false
            tutButton.isHidden = false
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
            tutButton.isHidden = false
        } // currently on name stack view, go back to welcome
    }
    
    // User pressed multiplayer button.
    @IBAction func multiplayerClicked(_ sender: Any) {
        self.backButton.isHidden = false
        self.gameTypeStackView.isHidden = true
        self.multiplayerStackView.isHidden = false
        Globals.instance.isMulti = true
    }
    
    // Change globals according to what segue is being taken.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "hostGame"){
            Globals.instance.isHosting = true
        }
        else if(segue.identifier == "joinGame"){
            Globals.instance.isHosting = false
        }
        initStyles()
        
        let handle = Cache.shared.object(forKey: "handle")
        Globals.instance.selfPeerID = MCPeerID(displayName: handle as! String)
    }
    
    // Initialize all UI on this view.
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

