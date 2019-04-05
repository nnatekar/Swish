//
//  File.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit

class MenuController : UIViewController {
    
    @IBOutlet weak var multiplayerStackView: UIStackView!
    @IBOutlet weak var gameTypeStackView: UIStackView!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        multiplayerStackView.isHidden = true
        backButton.isHidden = true
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
    }
}

