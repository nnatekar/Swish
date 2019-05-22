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
    // print "Move your camera around"
    case hostScanning // host will look around ARWorld, after 5 seconds host will automatically send map
    case peerScanning // peer will look around ARWorld
    
    // print "Sent world map/received world map from host" for 2 seconds
    case hostSentMap
    case peerReceivedMap
    
    // print "Everyone tap on the same yellow point to set up basket"
    case everyoneTapPoint
    
    // print "Everyone has tapped a point!"
    // popup UI "Are you ready? y/n"
    case readyStatus
    
    // hide messages
    case inGame
}
