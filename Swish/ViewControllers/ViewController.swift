//
//  ViewController.swift
//  Hoops
//
//  Created by Cazamere Comrie on 1/13/19.
//

import UIKit
import QuartzCore
import ARKit
import Each
import MultipeerConnectivity
import simd

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, ARSessionDelegate {

    @IBOutlet weak var scoreLabel: PaddingLabel!
    @IBOutlet weak var timerLabel: PaddingLabel!
    @IBOutlet weak var multiPlayerStatus: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructions: UILabel!
    @IBOutlet weak var worldStatus: UILabel!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var sendWorldMapButton: UIButton!
    @IBOutlet weak var countdownLabel: UILabel!
    
    /// Multipeer session being run.
    var multipeerSession: MultipeerSession!
    var gameTime = Double()
    var gameTimeMin = Int()
    var gameTimeSec = Int()
    /// Timer to get how long the game has been running.
    var gameTimer = Timer()
    
    var basketScene: SCNScene?
    /// Reference to the basket node in the scene.
    var globalBasketNode: SCNNode?
    /// Configuration of the AR World.
    let configuration = ARWorldTrackingConfiguration()
    /// Check if the basked has been added.
    var basketAdded: Bool = false
    var score: Int = 0
    /// Keeps track of the ARCamera's tracking state.
    var globalTrackingState: ARCamera.TrackingState?
    /// Reference to the current player's ARCamera.
    var globalCamera: ARCamera?
    /// Keeps track of where the player is in terms of setting up the game.
    var gameSetupState: gameInstructions!
    var positionAnchor: ARAnchor?
    var playerPositionAnchors: [String : ARAnchor] = [:]
    
    /// Keep track of how many players are ready to play.
    var readyPlayers: Int = 0
    var colorNum: Int = 0
    
    var hoopMove: Bool = false
    var mapAvailable: Bool = false
    
    var latestTranslatePos: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start AR session
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.autoenablesDefaultLighting = true
        sceneView.session.run(configuration)
        
        // Set up multipeer session's data handlers
        if(Globals.instance.isMulti){
            multipeerSession.dataHandler = dataHandler
            multipeerSession.basketSyncHandler = basketSyncHandler
        }

        // Set delegates for AR session and AR scene
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Tapping on the yellow dots will set basket
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false

        // pans will determine angle of basketball
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(sender:)))
        panGestureRecognizer.maximumNumberOfTouches = 1
        panGestureRecognizer.minimumNumberOfTouches = 1
        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // longpress will edit the location of the basket
        let pressGestureRecognizer = UILongPressGestureRecognizer(target:self, action:
            #selector(handlePress(sender:)))
        self.sceneView.addGestureRecognizer(pressGestureRecognizer)

        // add timer
        gameTime = 120 // CHANGE GAME TIME AS NEEDED, currently at 2 mins
        gameTimeMin = Int(gameTime) / 60
        gameTimeSec = Int(gameTime) % 60
        
        // initialize game state
        if(Globals.instance.isHosting){
            gameSetupState = .hostScanning
        }
        else{
            gameSetupState = .peerScanning
        }
        updateMultiPlayerStatus()
        
        initStyles();
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        basketScene = SCNScene(named: "Bball.scnassets/Basket.scn")
        // Set backboard texture
        basketScene?.rootNode.childNode(withName: "backboard", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "backboard.jpg")
        
        Globals.instance.scores.removeAll()
        Globals.instance.scores[Globals.instance.selfPeerID!] = 0
        colorNum = 0
    }
    
    // If segueing out of the game, disconnect from the multiplayer session.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "viewToLeaderboard"){
            if(Globals.instance.isHosting){
                multipeerSession.advert.stopAdvertisingPeer()
            }
        }
    }
    
    // When the user presses ready, start the game if singleplayer.
    // If multiplayer, send an acknowledgement of ready status to all peers.
    @IBAction func onReadyClick(_ sender: Any) {
        if Globals.instance.isMulti {
            // send true to all peers
            let codable = ArbitraryCodable(receivedData: "ready", num: self.score, isReady: true)
            guard let data = try? JSONEncoder().encode(codable)
                else {fatalError("can't encode ready")}
            self.multipeerSession.sendToAllPeers(data){
                self.readyButton.isHidden = true
                readyPlayers += 1
                if self.multipeerSession.connectedPeers.count == 0 {
                    DispatchQueue.main.async {
                        self.countdownLabel.isHidden = false
                        self.countdownToGame()
                    }
                }
                if(self.multipeerSession.connectedPeers.count + 1 == readyPlayers){
                    DispatchQueue.main.async {
                        self.countdownLabel.isHidden = false
                        self.countdownToGame()
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.countdownLabel.isHidden = false
                self.countdownToGame()
            }
        }
       
    }
    
    /**
      Animates the game start countdown.
    */
    func countdownToGame(){
        // first fade out
        UIView.animate(withDuration: 1, animations: {
            self.countdownLabel.alpha = 0.0
        }, completion: { (success) in
            if(success){
                // then change text, fade out again
                self.countdownLabel.text = "2..."
                self.countdownLabel.alpha = 1.0
                UIView.animate(withDuration: 1, animations: {
                    self.countdownLabel.alpha = 0.0
                }, completion: { (success) in
                    if(success){
                        self.countdownLabel.text = "1..."
                        self.countdownLabel.alpha = 1.0
                    }
                    UIView.animate(withDuration: 1, animations: {
                        self.countdownLabel.alpha = 0.0
                    }, completion: { (success) in
                        if(success){
                            self.countdownLabel.text = "GO!"
                            self.countdownLabel.alpha = 1.0
                            UIView.animate(withDuration: 1, animations: {
                                self.countdownLabel.alpha = 0.0
                            }, completion: { (success) in
                                if(success){
                                    self.countdownLabel.isHidden = true
                                    self.gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.incrementTimer), userInfo: nil, repeats: true)
                                }
                            })
                        }
                    })
                })
            }
        })
    }
    
    /**
        Initialize all UI for the game.
    */
    func initStyles(){
        instructions.numberOfLines = 0
        
        timerLabel.text = String(format: "%02d:%02d", gameTimeMin, gameTimeSec)
        timerLabel.font = timerLabel.font.withSize(24)
        timerLabel.textColor = UIColor.white
        timerLabel?.layer.cornerRadius = 2
        timerLabel.textAlignment = .center
        
        scoreLabel.text = "\(score)"
        scoreLabel.font = scoreLabel.font.withSize(24)
        scoreLabel.textColor = UIColor.white
        scoreLabel?.layer.cornerRadius = 2
        scoreLabel.textAlignment = .center
        
        countdownLabel.isHidden = true
    }

    // Physics world handles collisions between basket's collision node and balls.
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue {
            if (contact.nodeA.name! == "detection") {
                if (contact.nodeB.name! == Globals.instance.selfPeerID!.displayName && gameTimer != nil) {
                    self.score+=1
                    Globals.instance.scores[Globals.instance.selfPeerID!] = self.score
                    contact.nodeB.physicsBody?.collisionBitMask = CollisionCategory.ballCategory.rawValue
                    contact.nodeB.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
                    if Globals.instance.isMulti {
                        let codableScore = ArbitraryCodable(receivedData: "score", num: self.score, isReady: true)
                        guard let data = try? JSONEncoder().encode(codableScore)
                            else { fatalError("can't encode score") }
                        self.multipeerSession.sendToAllPeers(data){}
                    }
                }
                
                DispatchQueue.main.async {
                    self.scoreLabel.text = "\(self.score)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                    contact.nodeB.removeFromParentNode()
                }
            }
            
        }
    }

    /**
      Increments game timer to count down how much game time is left.
    */
    @objc func incrementTimer(){
        if basketAdded == true {
            gameTime -= 1
            gameTimeMin = Int(gameTime) / 60
            gameTimeSec = Int(gameTime) % 60
            
            DispatchQueue.main.async{
                self.timerLabel.text = String(format: "%02d:%02d", self.gameTimeMin, self.gameTimeSec)
            }
                
            if(gameTime <= 0){
                gameTimer.invalidate()
                self.performSegue(withIdentifier: "viewToLeaderboard", sender: self)

            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }

    /**
      Shoot the ball. Called when swiping.
     
     - parameters:
        - velocity: velocity of the user's swipe
        - translation: translation of the user's swipe
    */
    func shootBall(velocity: CGPoint, translation: CGPoint) {
        // Get user's point of view in the scene.
        guard let pointOfView = self.sceneView.pointOfView else {return}
        
        // Force the detection node to be exactly at it's presentation node's position.
        globalBasketNode!.childNodes[3].position = globalBasketNode!.childNodes[3].presentation.position
        
        // Get the position of the user.
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation

        // Add the ball.
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        if Globals.instance.isHosting || !Globals.instance.isMulti {
            ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "0.png") // Set ball texture
        } else {
            var string = String(colorNum) + ".png"
            ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: string)
        }
        ball.position = position
        
        // Set the ball's physics properties.
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = Globals.instance.selfPeerID!.displayName
        body.restitution = 1.05

        // Set the force at which the ball will shoot.
        let xForce = translation.x > 0 ? min(1.5, Float(translation.x)/100) : max(-1.5, Float(translation.x)/100)
        let yForce = min(10, Float(translation.y) / -300 * 8)
        let zForce = max(-3, Float(velocity.y) / 900)
        let force = SCNVector4(xForce, yForce, zForce,0.0)
        let rotatedForce = transform * force
        let vectorForce = SCNVector3(x:rotatedForce.x, y:rotatedForce.y, z:rotatedForce.z)
        ball.physicsBody?.applyForce(vectorForce, asImpulse: true)
        
        // Set ball's collision properties
        ball.physicsBody?.categoryBitMask = CollisionCategory.ballCategory.rawValue
        ball.physicsBody?.collisionBitMask = CollisionCategory.detectionCategory.rawValue

        let positionTransform = pointOfView.simdTransform
        
        // Add the ball to the scene and attach a timer to it.
        self.sceneView.scene.rootNode.addChildNode(ball) // create another ball after you shoot
        weak var ballObject = Ball(ballNode: ball)
        
        // Make sure all multiplayer code is only run if the current player is in multiplayer.
        guard Globals.instance.isMulti else {return}
        
        // Set up an anchor at the player's position. If one already exists, remove it.
        let anchorName = Globals.instance.selfPeerID!.displayName
        if(positionAnchor != nil){
            sceneView.session.remove(anchor: positionAnchor!)
        }
        positionAnchor = ARAnchor(name: anchorName, transform: positionTransform)
        sceneView.session.add(anchor: positionAnchor!)
        let codableCol1 = CodablePosition(dim1: positionTransform.columns.0.x, dim2: positionTransform.columns.0.y, dim3: positionTransform.columns.0.z, dim4: positionTransform.columns.0.w)
        let codableCol2 = CodablePosition(dim1: positionTransform.columns.1.x, dim2: positionTransform.columns.1.y, dim3: positionTransform.columns.1.z, dim4: positionTransform.columns.1.w)
        let codableCol3 = CodablePosition(dim1: positionTransform.columns.2.x, dim2: positionTransform.columns.2.y, dim3: positionTransform.columns.2.z, dim4: positionTransform.columns.2.w)
        let codableCol4 = CodablePosition(dim1: positionTransform.columns.3.x, dim2: positionTransform.columns.3.y, dim3: positionTransform.columns.3.z, dim4: positionTransform.columns.3.w)
        let basketPos = CodablePosition(dim1: globalBasketNode!.position.x, dim2: globalBasketNode!.position.y, dim3: globalBasketNode!.position.z, dim4: 0)
        let encodableTransform = CodableTransform(c1: codableCol1, c2: codableCol2, c3: codableCol3, c4: codableCol4, basketPos: basketPos, s: anchorName, fX: xForce, fY: yForce, fZ: zForce, colorNum: self.colorNum)

        do{
            // Send the anchor to the other players so they can see your balls.
            let data : Data = try JSONEncoder().encode(encodableTransform)
            self.multipeerSession.sendToAllPeers(data){}
        }
        catch{
            print("Was not able to encode transform to data")
        }
    } // create and shoot ball

    /**
      Called whenever the user holds their press.
    */
    @objc func handlePress(sender: UILongPressGestureRecognizer){
        guard let recognizerView = sender.view as? ARSCNView else { return }
        let touch = sender.location(in: recognizerView)
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        hoopMove = true
        
        // User just started pressing.
        if sender.state == .began {
            latestTranslatePos = touch
        }
        
        // User's press moved
        if sender.state == .changed {
            // make sure a node has been selected from .began
            guard let hitNode = self.globalBasketNode else { return }
            
            // perform a hitTest to obtain the plane
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            guard let hitPlane = hitTestPlane.first else { return }
            
            let deltaX = Float(touch.x - latestTranslatePos!.x)/5000
            let deltaY = Float(touch.y - latestTranslatePos!.y)/5000
            
            let transformHitPlane = SCNVector4(hitPlane.worldTransform.columns.3.x, hitPlane.worldTransform.columns.3.y, hitPlane.worldTransform.columns.3.z, hitPlane.worldTransform.columns.3.w)
            let transformBasket = transform * transformHitPlane

            hitNode.localTranslate(by: SCNVector3(deltaX,
                                                  0.0,
                                                  deltaY))
            } else if sender.state == .ended || sender.state == .cancelled || sender.state == .failed {
            hoopMove = false
        }
        
    }
    
    /**
      Called when user swipes.
    */
    @objc func handlePan(sender: UIPanGestureRecognizer){
        guard let sceneView = sender.view as? ARSCNView else {return}
        
        // Basket has been added and user just finished swiping
        if (basketAdded && sender.state == .ended && hoopMove == false){
            // Get the velocity and translation and shoot the ball.
            let velocity = sender.velocity(in: sceneView)
            let translation = sender.translation(in: sceneView)
            shootBall(velocity: velocity, translation : translation)
        }
    }

    /**
      Called when user taps screen.
    */
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)

        // Perform a hit test to get the location where the user tapped.
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])

        // If the hit test was successful, spawn a basket where the player tapped.
        if !hitTestResult.isEmpty {
            if(!basketAdded){
                self.addBasket(hitTestResult: hitTestResult.first!)
                gameSetupState = .inGame
                updateMultiPlayerStatus()
            }
        }
    }

    /**
      Add a basket to the scene.
     
     - parameters:
        - hitTestResult: results of the scenekit hit test
    */
    func addBasket(hitTestResult: ARHitTestResult) {
        // Make sure basket has not been added already
        if basketAdded == false {

            // Set basket textures
            basketScene?.rootNode.childNode(withName: "backboard", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "backboard.jpg")
            basketScene?.rootNode.childNode(withName: "pole", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray
            basketScene?.rootNode.childNode(withName: "detection", recursively: true)?.opacity = 0.0

            // Create and add an AR Anchor to the scene, which will then render to create the basket.
            let anchor = ARAnchor(name: "basketAnchor", transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.basketAdded = true
            }
            
        }
    }
    
    /**
      Render the basket after an anchor has been added to the session.
    */
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Basket has not been added yet and we just added a basket anchor.
        if(anchor.name == "basketAnchor" && !basketAdded){
            // Create a basket. It will be at the position of the anchor.
            let basketNode = basketScene!.rootNode.childNode(withName: "ball", recursively: false)
            basketNode?.childNodes[3].physicsBody?.centerOfMassOffset = SCNVector3(0,0,0)
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            basketAdded = true
            
            return basketNode
        }
        
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Share the AR World Map.
    */
    @IBAction func shareSession(_ button: UIButton) {
        // Check if the user is hosting.
        guard Globals.instance.isHosting else{ return }

        var count = 1
        for peer in multipeerSession.connectedPeers{
           let codable = ArbitraryCodable(receivedData: "color", num: count, isReady: false)
            guard let data = try? JSONEncoder().encode(codable)
                else {fatalError("can't encode ready")}
            multipeerSession.sendToPeer(data, id: peer)
            count += 1
        }
        
        // Make sure the AR world has been mapped completely before sending world map.
        if(mapAvailable){
            sceneView.session.getCurrentWorldMap { worldMap, error in
                guard let map = worldMap
                    else { print("Error: \(error!.localizedDescription)"); return }
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    else { fatalError("can't encode map") }
                
                // Send the world map to all players, and then hide the sendworldmap button.
                self.multipeerSession.sendToAllPeers(data){
                    self.sendWorldMapButton.isHidden = true
                }
                
                // Stop advertising; nobody else should join a session after world has been sent.
                self.multipeerSession.advert.stopAdvertisingPeer()
                
                // Send each peer the list of all peers.
                for peer in self.multipeerSession.connectedPeers{
                    guard let peerData = try? NSKeyedArchiver.archivedData(withRootObject: peer, requiringSecureCoding: true)
                        else { fatalError("can't encode peer list") }
                    self.multipeerSession.sendToAllPeers(peerData){}
                }
            }
        }
    }
    
    /**
      Handles world map syncing between players and the host.
     
     - parameters:
        - worldMap: the world map sent by the host
        - peerID: the peer ID of the host
    */
    func basketSyncHandler(worldMap: ARWorldMap, peerID: MCPeerID){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.initialWorldMap = worldMap
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        gameSetupState = .peerReceivedMap
        updateMultiPlayerStatus()
    }

    /**
      Handles data sent by a peer.
     - parameters:
        - data: data sent by peer
        - peer: peer ID of the peer who sent data
    */
    func dataHandler(_ data: Data, from peer: MCPeerID) {
        do{
            // If the data is a transform, we need to add an anchor at the transform and create a ball there
            let decodedData = try JSONDecoder().decode(CodableTransform.self, from: data)
            
            let col0 = simd_float4(decodedData.col1.dim1, decodedData.col1.dim2, decodedData.col1.dim3, decodedData.col1.dim4)
            let col1 = simd_float4(decodedData.col2.dim1, decodedData.col2.dim2, decodedData.col2.dim3, decodedData.col2.dim4)
            let col2 = simd_float4(decodedData.col3.dim1, decodedData.col3.dim2, decodedData.col3.dim3, decodedData.col3.dim4)
            let col3 = simd_float4(decodedData.col4.dim1, decodedData.col4.dim2, decodedData.col4.dim3, decodedData.col4.dim4)
            
            let tform = simd_float4x4(col0, col1, col2, col3)
            let anchor = ARAnchor(name: decodedData.playerID, transform: tform)
            let anchorPos = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
            
            // If there's already an anchor for that player, delete it first.
            if(!playerPositionAnchors.isEmpty){
                if(playerPositionAnchors[decodedData.playerID] != nil){
                    sceneView.session.remove(anchor: playerPositionAnchors[decodedData.playerID]!)  // remove existing anchor from sceneview
                }
            }
            
            playerPositionAnchors[decodedData.playerID] = anchor
            sceneView.session.add(anchor: anchor)
            
            let position = anchorPos
            let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
            
            let string = String(decodedData.colorNum) + ".png"
            ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: string)
            
            ball.position = SCNVector3(position.x, position.y, position.z)
            print(ball.position)
            let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
            ball.physicsBody = body
            ball.name = peer.displayName
            body.restitution = 1.05
            
            let xForce = decodedData.forceX
            let yForce = decodedData.forceY
            let zForce = decodedData.forceZ
            ball.physicsBody?.applyForce(SCNVector3(xForce, yForce, zForce), asImpulse: true)
            ball.physicsBody?.categoryBitMask = CollisionCategory.ballCategory.rawValue
            ball.physicsBody?.collisionBitMask = CollisionCategory.detectionCategory.rawValue
            sceneView.scene.rootNode.addChildNode(ball)
        }
        catch{
        }
        
        do{
            // If the data was an arbitrary codable, check what type of data was sent by checking
            // received data string.
            let decodedData = try JSONDecoder().decode(ArbitraryCodable.self, from: data)
            
            if decodedData.receivedData == "score" {
                Globals.instance.scores[peer] = decodedData.score
            } else if decodedData.receivedData == "ready" {
                readyPlayers += 1
                if readyPlayers == self.multipeerSession.connectedPeers.count + 1{
                    DispatchQueue.main.async{
                        self.countdownLabel.isHidden = false
                        self.countdownToGame()
                    }
                }
            } else if decodedData.receivedData == "color" {
                self.colorNum = decodedData.color
            }
        }
        catch{
            
        }
    }

    // called from ARSCNViewDelegate
    // SCNNode relating to a new anchor was added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if(anchor.name == "basketAnchor"){
            globalBasketNode = node
        }
    } // just to deal with planeDetected button on top. +2 to indicate button is there for 2 seconds and then disappears
    
    // called every frame
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    }

    // called when the state of the camera is changed
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        globalCamera = camera
    }

    // called when AR session fails
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user.
        multiPlayerStatus.text = "Session failed: \(error.localizedDescription)"
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // Whenever the camera frame updates, check the world mapping status
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        let position = frame.camera.transform.columns.3
        
        switch frame.worldMappingStatus {
            case .notAvailable:
                worldStatus.text = "Not available"
                mapAvailable = false
            case .limited:
                worldStatus.text = "Limited"
                mapAvailable = false
            case .extending:
                worldStatus.text = "Extending"
                mapAvailable = false
            case .mapped:
                worldStatus.text = "Mapped"
                mapAvailable = true
        }
    }

    /**
      Change the message in the middle of the game screen based on how far along the game
      setup the player is.
    */
    private func updateMultiPlayerStatus() {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch gameSetupState!{
        case .hostScanning:
            message = "Look around so we can get a map of the world. Tap a location to place your basket. Once you're ready, send your map to everyone by pressing send world map and ready buttons."
        case .peerScanning:
            if Globals.instance.isMulti{
                message = "Look around so we can get a map of the world. Wait for the host to send the map. Press ready to tell your peers to start!"
            } else {
                message = "Look around so we can get a map of the world. Tap a location to place your basket. Press ready to start!"
            }
        case .hostSentMap:
            message = "Sent the world map to peers."
        case .peerReceivedMap:
            message = "Received world map from peers."
        case .everyoneTapPoint:
            message = "Everyone tap a yellow dot in the same location!"
        case .readyStatus:
            message = "Everyone has tapped a point."
            // MAKE POPUP TO ASK PLAYERS IF THEY'RE READY AND START GAME
        case .inGame:
            message = ""
        default:
            message = ""
        }
        DispatchQueue.main.async {
            self.multiPlayerStatus.text = message
            self.multiPlayerStatus.isHidden = message.isEmpty
        }
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

extension SCNMatrix4 {
    static public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
        let x = left.m11*right.x + left.m21*right.y + left.m31*right.z + left.m41*right.w
        let y = left.m12*right.x + left.m22*right.y + left.m32*right.z + left.m42*right.w
        let z = left.m13*right.x + left.m23*right.y + left.m33*right.z + left.m43*right.w
        let w = left.m14*right.x + left.m24*right.y + left.m43*right.z + left.m44*right.w
        
        return SCNVector4(x: x, y: y, z: z, w: w)
    }
}
