//
//  CodablePosition.swift
//  Swish
//
//  Created by Neil Natekar on 5/8/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import ARKit

class ArbitraryCodable: Codable {
    var receivedData: String // "score"
    var score: Int
    var isReady: Bool
    
    init(receivedData: String, score: Int, isReady: Bool){
        self.score = score
        self.receivedData = receivedData
        self.isReady = isReady
    }
}

class CodableBall: Codable{
    var forceX: Float
    var forceY: Float
    var forceZ: Float
    var playerPosition: CodablePosition
    var basketPosition: CodablePosition

    
    // only working with 3d space
    init(forceX: Float, forceY: Float, forceZ: Float, playerPosition: CodablePosition, basketPosition: CodablePosition ){
        self.forceX = forceX
        self.forceY = forceY
        self.forceZ = forceZ
        self.playerPosition = playerPosition
        self.basketPosition = basketPosition
    }
}

class CodablePosition: Codable{
    var dim1: Float
    var dim2: Float
    var dim3: Float
    var dim4: Float
    
    // only working with 3d space
    init(dim1: Float, dim2: Float, dim3: Float, dim4: Float){
        self.dim1 = dim1
        self.dim2 = dim2
        self.dim3 = dim3
        self.dim4 = dim4
    }
}

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
    
    init(c1 : CodablePosition, c2 : CodablePosition, c3 : CodablePosition, c4 : CodablePosition, basketPos: CodablePosition, s : String, fX : Float, fY: Float, fZ : Float){
        self.col1 = c1
        self.col2 = c2
        self.col3 = c3
        self.col4 = c4
        self.playerID = s
        self.basketPos = basketPos
        self.forceX = fX
        self.forceY = fY
        self.forceZ = fZ
    }
}
