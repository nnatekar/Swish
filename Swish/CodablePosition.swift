//
//  CodablePosition.swift
//  Swish
//
//  Created by Neil Natekar on 5/8/19.
//

import Foundation
import ARKit

/**
  An arbitrary codeable with a string, int and a bool that
  can be sent to other players.
 */
class ArbitraryCodable: Codable {
    var receivedData: String // "score", "color"
    var score: Int
    var color: Int
    var isReady: Bool
    
    init(receivedData: String, num: Int, isReady: Bool){
        self.score = 0
        self.color = 0
        
        if receivedData == "score" {
            self.score = num
        } else if receivedData == "color" {
            self.color = num
        }
        
        self.receivedData = receivedData
        self.isReady = isReady
    }
}

/**
  A codable ball with force, player position, and a ball position that can be sent to
  other players.
 */
class CodableBall: Codable{
    var forceX: Float
    var forceY: Float
    var forceZ: Float
    var playerPosition: CodablePosition
    var basketPosition: CodablePosition
    
    // only working with 3d space
    init(colorNum: Int, forceX: Float, forceY: Float, forceZ: Float, playerPosition: CodablePosition, basketPosition: CodablePosition ){
        self.forceX = forceX
        self.forceY = forceY
        self.forceZ = forceZ
        self.playerPosition = playerPosition
        self.basketPosition = basketPosition
    }
}

/**
  A codeable position of an object with up to 4 dimensions that could be sent to other players.
 */
class CodablePosition: Codable{
    var dim1: Float
    var dim2: Float
    var dim3: Float
    var dim4: Float
    
    // only working with 3d space to send balls
    init(dim1: Float, dim2: Float, dim3: Float, dim4: Float){
        self.dim1 = dim1
        self.dim2 = dim2
        self.dim3 = dim3
        self.dim4 = dim4
    }
}

/**
  A codeable 4x4 transform with a basket position, force, and a string that can be sent to other players.
 */
class CodableTransform: Codable{
    var col1 : CodablePosition
    var col2 : CodablePosition
    var col3 : CodablePosition
    var col4 : CodablePosition
    var basketPos: CodablePosition
    var forceX: Float
    var forceY: Float
    var forceZ: Float
    var playerID : String
    var colorNum: Int
    
    init(c1 : CodablePosition, c2 : CodablePosition, c3 : CodablePosition, c4 : CodablePosition, basketPos: CodablePosition, s : String, fX : Float, fY: Float, fZ : Float, colorNum: Int){
        self.col1 = c1
        self.col2 = c2
        self.col3 = c3
        self.col4 = c4
        self.playerID = s
        self.basketPos = basketPos
        self.forceX = fX
        self.forceY = fY
        self.forceZ = fZ
        self.colorNum = colorNum
    }
}
