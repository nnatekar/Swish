//
//  ViewController.swift
//  Hoops
//
//  Created by Cazamere Comrie on 1/13/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

/*
Basic notes:

 1. App is built for use in the "outside", meaning I have yet to initialize a hoop onto a vertical plane. So when hoop is created, it just hovers in the air. Need to add hoop stand and also functionality to place on a vertical wall.
 2. Distance has not been factored into the design yet. Need to come up with simple way to determine 2 vs 3 pt (i.e. what is the distance cut off?).
 3. Both basketball and backboard look boring, need to find and add textures
 4. NEED TO ADD POINT SYSTEM! Just +2 whenever it goes in initially and then add distance for three pointers-accumulate points in the background and pop up +2 or +3 in top right-add two button to same place on Main.storyboard-simple if statement
 5. Add timer-just 30 seconds initially to get score and then display final score-then reset to 0-maybe need to add a timer button to the HUD just for now to test all the mechanics
 
 */

import UIKit
import ARKit
import Each
class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var timerLabel: UILabel!
    var gameTime = Int()
    var gameTimer = Timer()
    
    @IBOutlet weak var planeDetected: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 1
    let timer = Each(0.05).seconds
    var basketAdded: Bool = false
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        // add timer
        gameTime = 30 // CHANGE GAME TIME AS NEEDED
        timerLabel.text = "Time: \(gameTime)"
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementTimer), userInfo: nil, repeats: true)
    }
    
    @objc func incrementTimer(){
        gameTime -= 1
        timerLabel.text = "Time: \(gameTime)"
        
        if(gameTime <= 0){
            gameTimer.invalidate()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            timer.perform(closure: { () -> NextStep in
                self.power = self.power + 1
                return .continue
            })
        }
    } // called when you touch phone-if ball is on scene view, will add power to shot by holding
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            self.timer.stop()
            self.shootBall()
        }
        self.power = 1
    } // called when you lift finger off-calls shootBall() to shoot the ball da doiiii
    
    func shootBall() {
        
        guard let pointOfView = self.sceneView.pointOfView else {return}
        self.removeEveryOtherBall()
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.blue // TODO: find texture and add
        ball.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = "Basketball"
        body.restitution = 0.2
        ball.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true) // TODO: change from tap and hold to flick
        self.sceneView.scene.rootNode.addChildNode(ball) // create another ball after you shoot
        
        
    } // create and shoot ball
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
        }
    }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        if basketAdded == false {
            let basketScene = SCNScene(named: "Ball.scn") // TODO: create nicer backboard
            let basketNode = basketScene?.rootNode.childNode(withName: "ball", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            let xPosition = positionOfPlane.x
            let yPosition = positionOfPlane.y
            let zPosition = positionOfPlane.z
            basketNode?.position = SCNVector3(xPosition,yPosition,zPosition)
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            self.sceneView.scene.rootNode.addChildNode(basketNode!)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.basketAdded = true
            }
        }
    } // adds backboard and hoop to the scene view
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.planeDetected.isHidden = true
        }
    } // just to deal with planeDetected button on top. +2 to indicate button is there for 2 seconds and then disappears
    
    func removeEveryOtherBall() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "Basketball" {
                node.removeFromParentNode()
            }
        }
    } // remove the balls yooo
    
    deinit {
        self.timer.stop()
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
} // useful operator to add 3D vectors

