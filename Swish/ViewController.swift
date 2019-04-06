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
<<<<<<< HEAD
import MultipeerConnectivity
class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
=======
class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    var gameTime = Int()
    var gameTimer = Timer()
    
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var multiPlayerStatus: UILabel!
    
    var selfHandle: MCPeerID?
    var multipeerSession: MultipeerSession!
    var mapProvider: MCPeerID?

    var isMultiplayer: Bool = false
    
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 1
    let timer = Each(0.05).seconds
    var basketAdded: Bool = false
<<<<<<< HEAD
    
    var receivingForce: SCNVector3?
=======
    var score: Int = 0
    
    // added
    
    
    // var add1 = false
    // var add2 = false
    // var add = [add1, add2]
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // start view's AR session
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.autoenablesDefaultLighting = true
        sceneView.session.run(configuration)
        
        multipeerSession = MultipeerSession(peerID: selfHandle!, receivedDataHandler: dataHandler)
        // Set delegates for AR session and AR scene
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // taps will set basketball
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        // pans will determine angle of basketball
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.minimumNumberOfTouches = 1
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // add timer
<<<<<<< HEAD
        gameTime = 30 // CHANGE GAME TIME AS NEEDED
        timerLabel.text = "Time: \(gameTime)"
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementTimer), userInfo: nil, repeats: true)
=======
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
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
    }
    
    
<<<<<<< HEAD
    @objc func incrementTimer(){
        gameTime -= 1
        timerLabel.text = "Time: \(gameTime)"
        
        if(gameTime <= 0){
            gameTimer.invalidate()
=======
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded == true {
            self.timer.stop()
            self.shootBall()
            //print("shot")
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // stop the AR session if leaving the view
        sceneView.session.pause()
    }
    
    func shootBall(velocity: CGPoint, translation: CGPoint) {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        self.removeEveryOtherBall()
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture.png") // Set ball texture
        ball.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = "Basketball"
        body.restitution = 0.2
<<<<<<< HEAD
        let velocityY = abs(Float(velocity.y)) / -100
        ball.physicsBody?.applyForce(SCNVector3(0,3,velocityY), asImpulse: true) // TODO: Determine force to be applied
        self.sceneView.scene.rootNode.addChildNode(ball) // create another ball after you shoot

        let ballpower = Data(buffer: UnsafeBufferPointer(start: &power, count: 1))
        self.multipeerSession.sendToAllPeers(ballpower)
        
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: ball, requiringSecureCoding: true)
                else { fatalError("can't encode ball") }
        self.multipeerSession.sendToAllPeers(data)
=======
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
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
    } // create and shoot ball
    
    @objc func handlePan(sender: UIPanGestureRecognizer){
        guard let sceneView = sender.view as? ARSCNView else {return}
        
        if basketAdded == true {
            let velocity = sender.velocity(in: sceneView);
            let translation = sender.translation(in: sceneView)
            shootBall(velocity: velocity, translation : translation);
        }
    }
    
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
<<<<<<< HEAD
            let basketScene = SCNScene(named: "Ball.scn")
            
            // Set backboard texture
            basketScene?.rootNode.childNode(withName: "backboard", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "backboard.jpg")
            
            let basketNode = basketScene?.rootNode.childNode(withName: "ball", recursively: false)
           
=======
            let basketScene = SCNScene(named: "Bball.scnassets/Basket.scn") // TODO: create nicer backboard
            let basketNode = basketScene?.rootNode.childNode(withName: "ball", recursively: false)
           // let detectionNode = basketScene?.rootNode.childNode(withName: "detection", recursively: false)
>>>>>>> 5dd5831e7154ba24c7d952d8e78beda80b81c24e
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
    
    @IBAction func shareSession(_ button: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
    }
    
    func dataHandler(_ data: Data, from peer: MCPeerID) {
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else{
                if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                    // Add anchor to the session, ARSCNView delegate adds visible content.
                    sceneView.session.add(anchor: anchor)
                } 
                else{
                    print("unknown data recieved from \(peer)")
                }
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
        do{
            // get the ball from other player and add it to scene
            if let ball = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data){
                let transform = sceneView.pointOfView!.transform
                let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
                ball.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
                sceneView.scene.rootNode.addChildNode(ball)
                print("Adding a new ball!")
            }
        }
        catch{
            print("Object isn't scenenode either")
        }
        
        do{
            // get the ball from other player and add it to scene
            if let force : Float = data.withUnsafeBytes({ $0.pointee }){
                power = force
                print("got the force")
            }
        }
        catch{
            print("Object isn't scenenode either")
        }
    }
    
    // called from ARSCNViewDelegate
    // SCNNode relating to a new anchor was added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.planeDetected.isHidden = true
        }
    } // just to deal with planeDetected button on top. +2 to indicate button is there for 2 seconds and then disappears
    
    // called every frame
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    // MARK: - ARSessionDelegate
    
    // called when the state of the camera is changed
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateMultiPlayerStatus(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    // called when AR session fails
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        multiPlayerStatus.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    
    //resets the AR session configuration in case of errors
    func resetTracking() {
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - AR session management
    
    private func updateMultiPlayerStatus(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        
        multiPlayerStatus.text = message
        multiPlayerStatus.isHidden = message.isEmpty
    }
    
    
    
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

