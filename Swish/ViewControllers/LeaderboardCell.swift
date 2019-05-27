//
//  LeaderboardCell.swift
//  Swish
//
//  Created by Tran Nguyen on 5/22/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit

class LeaderboardCell: UITableViewCell {
    @IBOutlet weak var rank: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var score: UILabel!
    
    func updateViews(r: Int, n: String, s: Int){
        rank.text = String(r)
        name.text = n
        score.text = String(s)
        
    }
}
