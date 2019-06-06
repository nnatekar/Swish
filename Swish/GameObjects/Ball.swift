//
//  Ball.swift
//  Swish
//
//  Created by Neil Natekar on 5/26/19.
//

import SceneKit

/*
    The Ball class is used to attach a timer to each ball so it gets destroyed after a few seconds.
 */
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
    
    /**
     Destroy the ball after a few seconds.
    */
    @objc func ballDestroy(){
        lifeTime += 1
        
        if(lifeTime >= 5){
            ballNode.removeFromParentNode()
            gameTimer.invalidate()
        }
    }
}
