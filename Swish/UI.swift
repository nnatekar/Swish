//
//  UI.swift
//  Swish
//
//  Created by Tran Nguyen on 4/29/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class PaddingLabel: UILabel {
    
    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 5.0
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: rect.inset(by:insets))
    }
    
}

enum gameInstructions{
    // 1) Everyone scans ar world map
    // 2) Host sets up basket and sends the world map. Everyone else waits
    // 3) Peers set up basket. Host presses ready.
    // 4) Peers press ready.
    // 5) Everyone is ready -> game starts
    
    case scanning // host will look around ARWorld to scan
    
    case hostSettingUpBasket // "Tap to place basket. To move basket, tap and hold. Send World Map when ready."
    case peerWaiting // "Wait for the host to send the world map."
    
    case peerSettingUpBasket // "Tap to place basket. To move basket, tap and hold. Place the basket in the same position as other players."
    
    case basketAdded // "Wait for all players to set up the basket."
    
    // print "Everyone has set up the basket."
    // popup UI "Are you ready? y/n"
    case readyStatus
    
    // hide messages
    case inGame
}
