//
//  ViewController.swift
//  Hoops
//
//  Created by Cazamere Comrie on 1/13/19.
//  Copyright © 2019 Cazamere Comrie. All rights reserved.
//

/*
Basic notes:

 SWISH SHOULD BE A SPECIAL SHOT WHERE YOU DONT HIT THE RIM AND GET WAY MORE POINTS! LIKE DOUBLE?
 Implement distance
 
 */

import UIKit
import ARKit
import Each
class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    var gameTimer = Timer()
    var gameTime = Int()
    
    @IBOutlet weak var planeDetected: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 1
    let timer = Each(0.05).seconds
    var basketAdded: Bool = false
    var score: Int = 0
    
    // added
    
    
    // var add1 = false
    // var add2 = false
    // var add = [add1, add2]
    
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
        gameTime = 5 // CHANGE GAME TIME AS NEEDED
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            self.timerLabel.text = "Time: \(self.gameTime)"
            if(self.gameTime > 0){
                self.gameTime -= 1
            }
            else{
                self.gameTimer.invalidate()
            }
        })
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        print("** Collision!! " + contact.nodeA.name! + " hit " + contact.nodeB.name!)
        
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue {
            //add2 = true
            //if (contact.nodeA.name! == "detection" || contact.nodeB.name! == "detection") {
            if (contact.nodeB.name! == "detection") {
                /*
                 if (contact.nodeA.name! != "torusDetection" || contact.nodeB.name! != "torusDetection") {
                 score+=1
                */
                score+=1
                //add1 = true
            }else{
              //  score+=1
            }
            /*
             let anchorPosition = anchor.transforms.columns.3
             let cameraPosition = camera.transform.columns.3
             
             // here’s a line connecting the two points, which might be useful for other things
             let cameraToAnchor = cameraPosition - anchorPosition
             // and here’s just the scalar distance
             let distance = length(cameraToAnchor)
             //maybe do temp score-so from top of function add everything to a tempScore variable-feed this into the distance caluclation above and once you've got the final score for a given shot, add this to score?
            */
            print(score)
            // added
            // if (add2 == true && add1 = false) {score-=5}
            DispatchQueue.main.async {
                contact.nodeA.removeFromParentNode()
                //self.scoreLabel.text = String(self.score)
                //contact.nodeB.removeFromParentNode()   // node B is the net
                //self.addDetection()
             //   self.scoreLabel.text = String(self.score)
            }
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
            //print("shot")
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
        ball.physicsBody?.categoryBitMask = CollisionCategory.ballCategory.rawValue
        ball.physicsBody?.collisionBitMask = CollisionCategory.detectionCategory.rawValue
        self.sceneView.scene.rootNode.addChildNode(ball) // create another ball after you shoot
        let detection = SCNNode(geometry: SCNCylinder(radius: 0.2, height: 0.2))
        let body2 = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: detection))
        detection.physicsBody = body2
       // let positionOfPlane = hitTestResult.worldTransform.columns.3
        //let xPosition = positionOfPlane.x
        //let yPosition = positionOfPlane.y
        //let zPosition = positionOfPlane.z
        detection.position = SCNVector3(0,0.8,-3)
        detection.name = "detection"
       // detection.isHidden = true
        detection.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
        detection.physicsBody?.contactTestBitMask = CollisionCategory.ballCategory.rawValue
        self.sceneView.scene.rootNode.addChildNode(detection)
    } // create and shoot ball
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
        if !hitTestResult.isEmpty {
            self.addBasket(hitTestResult: hitTestResult.first!)
        }
    }
    
    //func addDetection()
    
    func addBasket(hitTestResult: ARHitTestResult) {
        if basketAdded == false {
            let basketScene = SCNScene(named: "Bball.scnassets/Basket.scn") // TODO: create nicer backboard
            let basketNode = basketScene?.rootNode.childNode(withName: "ball", recursively: false)
           // let detectionNode = basketScene?.rootNode.childNode(withName: "detection", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            let xPosition = positionOfPlane.x
            let yPosition = positionOfPlane.y
            let zPosition = positionOfPlane.z
            basketNode?.position = SCNVector3(xPosition,yPosition,zPosition)
            //changed
            //detectionNode?.position = SCNVector3(xPosition,yPosition + 1.5,zPosition - 3)
            //detectionNode?.position = SCNVector3(xPosition,yPosition + 1.4,zPosition - 3)
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            //detectionNode?.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
            //detectionNode?.physicsBody?.collisionBitMask = CollisionCategory.ballCategory.rawValue
            //added
            //let detectionNode2 = basketScene?.rootNode.childNode(withName: "detection", recursively: false)
            //detectionNode2?.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
            //detectionNode2?.physicsBody?.collisionBitMask = CollisionCategory.ballCategory.rawValue
            
            //
            self.sceneView.scene.rootNode.addChildNode(basketNode!)
            //self.sceneView.scene.rootNode.addChildNode(detectionNode!)
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

struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let ballCategory  = CollisionCategory(rawValue: 1 << 0)
    static let detectionCategory = CollisionCategory(rawValue: 1 << 1)
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
} // useful operator to add 3D vectors

