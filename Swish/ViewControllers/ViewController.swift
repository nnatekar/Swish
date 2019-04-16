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
import MultipeerConnectivity
class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
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
    
    var receivingForce: SCNVector3?
    
    var gameBoard = GameBoard()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene.rootNode.addChildNode(gameBoard)
        
        // start view's AR session
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.autoenablesDefaultLighting = true
        sceneView.session.run(configuration)
        
        if(Globals.instance.isHosting){
            multipeerSession = MultipeerSession(hostPeerID: Globals.instance.selfPeerID!)
        }
        else{
            multipeerSession = MultipeerSession(selfPeerID: Globals.instance.selfPeerID!)
        }
        multipeerSession.dataHandler = dataHandler
        // Set delegates for AR session and AR scene
        sceneView.delegate = self
        sceneView.session.delegate = self
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        // stop the AR session if leaving the view
        sceneView.session.pause()
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

        let ballpower = Data(buffer: UnsafeBufferPointer(start: &power, count: 1))
        self.multipeerSession.sendToAllPeers(ballpower)
        
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: ball, requiringSecureCoding: true)
                else { fatalError("can't encode ball") }
        self.multipeerSession.sendToAllPeers(data)
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
            let anchor = ARAnchor(transform: hitTestResult.worldTransform)
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
        
        // get the ball from other player and add it to scene
        if let force : Float = data.withUnsafeBytes({ $0.pointee }){
            power = force
            print("got the force")
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
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers!.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers!.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers!.map({ $0.displayName }).joined(separator: ", ")
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

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
} // useful operator to add 3D vectors

