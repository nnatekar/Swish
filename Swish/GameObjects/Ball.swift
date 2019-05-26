//
//  Ball.swift
//  Swish
//
//  Created by Neil Natekar on 5/26/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

import SceneKit

class Ball{
    var ballNode = SCNNode()
    private var gameTimer = Timer()
    private var lifeTime = Int()
    
    init(ballNode: SCNNode){
        self.ballNode = ballNode
        lifeTime = 0
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ballDestroy), userInfo: nil, repeats: true)
    }
    
    deinit{
    }
    
    @objc func ballDestroy(){
        lifeTime += 1
        
        if(lifeTime >= 5){
            ballNode.removeFromParentNode()
            gameTimer.invalidate()
        }
    }
}
