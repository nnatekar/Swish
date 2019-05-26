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
    @IBOutlet weak var handleField: UITextField!
    @IBOutlet weak var gamesTableContainer: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        gamesTableContainer.isHidden = !(Globals.instance.isMulti)
        // temporary until we finish this view controller
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toGame"{
            let vc = segue.destination as! ViewController
            vc.multipeerSession = Globals.instance.session
        }
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toGame", sender: Any?.self)
        }
    }
}
