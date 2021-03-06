//
//  LeaderboardController.swift
//  Swish
//
//  Created by Tran Nguyen on 5/14/19.
//

import UIKit
import MultipeerConnectivity

class LeaderboardController: UIViewController {
    @IBOutlet weak var leaderboardTable: UITableView!
    var sortedScores: [(key: MCPeerID, value: Int)] = []
    var playerRank: Int = 0
    
    
    override func viewDidLoad() {
        leaderboardTable.delegate = self
        leaderboardTable.dataSource = self
        sortedScores = Globals.instance.scores.sorted(by: {$0.value > $1.value})
        leaderboardTable.reloadData()
    }
    
    @IBAction func onTouchNext(_ sender: Any) {
        if Globals.instance.isMulti{ self.presentingViewController!.presentingViewController!.presentingViewController!.dismiss(animated: true, completion:nil)
            Globals.instance.session!.session.disconnect()
        } else{
            self.presentingViewController!.presentingViewController!.dismiss(animated: true, completion:nil)
        }
    }
}

extension LeaderboardController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension LeaderboardController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Globals.instance.scores.count
    }
    
    // update each cell in the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var count = 0
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "leaderboardCell", for: indexPath) as? leaderboardCell {
            var score = 0
            var playerName = ""
            
            for (key, _) in sortedScores {
                if count == playerRank {
                    playerName = key.displayName
                    score = Globals.instance.scores[key]!
                }
                count += 1
            }
            
            cell.updateViews(r: playerRank+1, n: playerName, s: score)
            
            playerRank += 1
            return cell
        } else {
            return leaderboardCell()
        }
    }
}

class leaderboardCell: UITableViewCell {
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
