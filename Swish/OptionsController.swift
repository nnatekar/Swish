//
//  OptionsController.swift
//  Swish
//
//  Created by Jugal Jain on 2/27/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit

class OptionsController: UIViewController {
    
    
    @IBOutlet weak var GameStart: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // temporary until we finish this view controller
    }
    
    @IBAction func startClicked(_ sender: Any) {
        performSegue(withIdentifier: "toGame", sender: nil)
    }
}
