//
//  CodablePosition.swift
//  Swish
//
//  Created by Neil Natekar on 5/8/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import Foundation
import ARKit

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
