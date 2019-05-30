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
import QuartzCore
import ARKit
import Each
import MultipeerConnectivity
import simd

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate, ARSessionDelegate {

    @IBOutlet weak var scoreLabel: PaddingLabel!
    @IBOutlet weak var timerLabel: PaddingLabel!
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var multiPlayerStatus: UILabel!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructions: UILabel!
    @IBOutlet weak var worldStatus: UILabel!
    

    var selfHandle: MCPeerID?
    var multipeerSession: MultipeerSession!
    var mapProvider: MCPeerID?
    var isMultiplayer: Bool = false
    var gameTime = Double()
    var syncTime = Int()
    var gameTimeMin = Int()
    var gameTimeSec = Int()
    var gameTimeMs = Int()
    var gameTimer = Timer()
    var syncingTimer = Timer()
    
    var basketScene: SCNScene?
    var globalBasketNode: SCNNode?
    let configuration = ARWorldTrackingConfiguration()
    var power: Float = 1
    let timer = Each(0.05).minutes
    var basketAdded: Bool = false
    var receivingForce: SCNVector3?
    var score: Int = 0
    var scorePeer: Int = 0
    var hostPosition: CodablePosition?
    var playerPosition: CodablePosition?
    var cameraTrackingState: ARCamera.TrackingState?
    var globalCamera: ARCamera?
    var gameSetupState: gameInstructions!
    var numTappedPoints = Int()
    var positionAnchor: ARAnchor?
    var playerPositionAnchors: [String : ARAnchor] = [:]
    
    var hoopMove: Bool = false
    var mapAvailable: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // start view's AR session
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        configuration.planeDetection = .horizontal
        sceneView.autoenablesDefaultLighting = true
        sceneView.session.run(configuration)
        
        // set up multipeer session's data handlers
        if(Globals.instance.isMulti){
            multipeerSession.dataHandler = dataHandler
            multipeerSession.basketSyncHandler = basketSyncHandler
        }

        // Set delegates for AR session and AR scene
        sceneView.delegate = self
        sceneView.session.delegate = self

        // taps will set basket
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
        syncTime = 5
        gameTime = 180 // CHANGE GAME TIME AS NEEDED, currently at 3 mins
        gameTimeMin = Int(gameTime) / 60
        gameTimeSec = Int(gameTime) % 60
        gameTimeMs = Int((gameTime * 1000).truncatingRemainder(dividingBy: 1000))
        
        // initialize game state
        if(Globals.instance.isHosting){
            gameSetupState = .hostScanning
        }
        else{
            gameSetupState = .peerScanning
        }
        updateMultiPlayerStatus()
        
        numTappedPoints = 0
        initStyles();
        
        // create the timer for the game and for sending world maps
        gameTimer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(incrementTimer), userInfo: nil, repeats: true)
        syncingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(syncTimer), userInfo: nil, repeats: false)
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        basketScene = SCNScene(named: "Bball.scnassets/Basket.scn")
        // Set backboard texture
        basketScene?.rootNode.childNode(withName: "backboard", recursively:
            true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "backboard.jpg")
        
        if(Globals.instance.isMulti){
            Globals.instance.scores.removeAll()
            
            let selfID = Globals.instance.selfPeerID
            Globals.instance.scores[selfID!] = 0
        }
    }
    
    func initStyles(){
//        planeDetected.text = "Point your camera towards the floor."
//        planeDetected.isHidden = false
//        planeDetected.font = planeDetected.font.withSize(28)
//        planeDetected.textColor = UIColor.white
//        planeDetected.layer.cornerRadius = 2
//        planeDetected.textAlignment = .center
//        planeDetected.numberOfLines = 0
//        planeDetected.shadowColor = UIColor.black
        
        instructions.numberOfLines = 0
        
        timerLabel.text = String(format: "%02d:%02d:%03d", gameTimeMin, gameTimeSec, gameTimeMs)
        timerLabel.font = timerLabel.font.withSize(24)
        timerLabel.textColor = UIColor.white
        timerLabel?.layer.cornerRadius = 2
        timerLabel.textAlignment = .center
        
        scoreLabel.text = "\(score)"
        scoreLabel.font = scoreLabel.font.withSize(24)
        scoreLabel.textColor = UIColor.white
        scoreLabel?.layer.cornerRadius = 2
        scoreLabel.textAlignment = .center
        
        stopButton?.layer.cornerRadius = 2
    }
    
    @IBAction func endClick(_ sender: Any){
        
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue
            || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.detectionCategory.rawValue {
            if (contact.nodeA.name! == "detection") {
                if (contact.nodeB.name! == selfHandle?.displayName) {
                    self.score+=1
                    Globals.instance.scores[selfHandle!] = self.score
                    let codableScore = ArbitraryCodable(receivedData: "score", score: self.score)
                    guard let data = try? JSONEncoder().encode(codableScore)
                        else { fatalError("can't encode score") }
                    self.multipeerSession.sendToAllPeers(data)
                }
                
                
                DispatchQueue.main.async {
                    self.scoreLabel.text = "\(self.score)"
                }
            }
            DispatchQueue.main.async {
                contact.nodeB.removeFromParentNode()
            }
        }
    }

    @objc func syncTimer(){
        syncTime -= 1
        
        
        if(syncTime <= 0){
            guard Globals.instance.isHosting else{ return }
            guard Globals.instance.isMulti else{ return }
            
            if mapAvailable {
                sceneView.session.getCurrentWorldMap { worldMap, error in
                    guard let map = worldMap
                        else { print("Error: \(error!.localizedDescription)"); return }
                    guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                        else { fatalError("can't encode map") }
                    self.multipeerSession.sendToAllPeers(data)
                }
                
                gameSetupState = .hostSentMap
                syncingTimer.invalidate()
                updateMultiPlayerStatus()
            }
        }
    }

    @objc func incrementTimer(){
        if basketAdded == true {
            gameTime -= 0.001
            gameTimeMin = Int(gameTime) / 60
            gameTimeSec = Int(gameTime) % 60
            gameTimeMs = Int((gameTime * 1000).truncatingRemainder(dividingBy: 1000))
            
            timerLabel.text = String(format: "%02d:%02d:%03d", gameTimeMin, gameTimeSec, gameTimeMs)
            
            if(gameTime <= 0){
                gameTimer.invalidate()

            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        sceneView.session.pause()
    }

    func shootBall(velocity: CGPoint, translation: CGPoint) {
        guard let pointOfView = self.sceneView.pointOfView else {return}
        
        globalBasketNode!.childNodes[3].position = globalBasketNode!.childNodes[3].presentation.position
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation

        // add the ball
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture.png") // Set ball texture
        ball.position = position
        
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = body
        ball.name = selfHandle?.displayName
        body.restitution = 0.2

        let xForce = translation.x > 0 ? min(1.5, Float(translation.x)/100) : max(-1.5, Float(translation.x)/100)
        let yForce = min(10, Float(translation.y) / -300 * 8)
        let zForce = max(-3, Float(velocity.y) / 900)
        let force = SCNVector4(xForce, yForce, zForce,0.0)
        let rotatedForce = transform * force
        let vectorForce = SCNVector3(x:rotatedForce.x, y:rotatedForce.y, z:rotatedForce.z)
        
        ball.physicsBody?.applyForce(vectorForce, asImpulse: true)
        ball.physicsBody?.categoryBitMask = CollisionCategory.ballCategory.rawValue
        ball.physicsBody?.collisionBitMask = CollisionCategory.detectionCategory.rawValue
        
        let positionTransform = pointOfView.simdTransform
        guard self.isMultiplayer else {return}
        
        let anchorName = self.selfHandle?.displayName
        if(positionAnchor != nil){
            sceneView.session.remove(anchor: positionAnchor!)
        }
        positionAnchor = ARAnchor(name: anchorName!, transform: positionTransform)
        sceneView.session.add(anchor: positionAnchor!)
        let codableCol1 = CodablePosition(dim1: positionTransform.columns.0.x, dim2: positionTransform.columns.0.y, dim3: positionTransform.columns.0.z, dim4: positionTransform.columns.0.w)
        let codableCol2 = CodablePosition(dim1: positionTransform.columns.1.x, dim2: positionTransform.columns.1.y, dim3: positionTransform.columns.1.z, dim4: positionTransform.columns.1.w)
        let codableCol3 = CodablePosition(dim1: positionTransform.columns.2.x, dim2: positionTransform.columns.2.y, dim3: positionTransform.columns.2.z, dim4: positionTransform.columns.2.w)
        let codableCol4 = CodablePosition(dim1: positionTransform.columns.3.x, dim2: positionTransform.columns.3.y, dim3: positionTransform.columns.3.z, dim4: positionTransform.columns.3.w)
        let basketPos = CodablePosition(dim1: globalBasketNode!.position.x, dim2: globalBasketNode!.position.y, dim3: globalBasketNode!.position.z, dim4: 0)
        let encodableTransform = CodableTransform(c1: codableCol1, c2: codableCol2, c3: codableCol3, c4: codableCol4, basketPos: basketPos, s: anchorName!, fX: xForce, fY: yForce, fZ: zForce)
        if(Globals.instance.isMulti){
            do{
                let data : Data = try JSONEncoder().encode(encodableTransform)
                self.multipeerSession.sendToAllPeers(data)
            }
            catch{
                print("Was not able to encode transform to data")
            }
        }
        
        let disappearingBall = Ball(ballNode: ball)
        self.sceneView.scene.rootNode.addChildNode(ball) // create another ball after you shoot
    } // create and shoot ball

    
    @objc func handlePress(sender: UILongPressGestureRecognizer){
        guard let recognizerView = sender.view as? ARSCNView else { return }
        let touch = sender.location(in: recognizerView)
        guard let pointOfView = self.sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        hoopMove = true
        
        if sender.state == .changed {
            // make sure a node has been selected from .began
            guard let hitNode = self.globalBasketNode else { return }
            
            // perform a hitTest to obtain the plane
            let hitTestPlane = self.sceneView.hitTest(touch, types: .existingPlane)
            guard let hitPlane = hitTestPlane.first else { return }
            let transformHitPlane = SCNVector4(hitPlane.worldTransform.columns.3.x, hitPlane.worldTransform.columns.3.y, hitPlane.worldTransform.columns.3.z, hitPlane.worldTransform.columns.3.w)
            let transformBasket = transform * transformHitPlane

            hitNode.position = SCNVector3(transformBasket.x,
                                          transformBasket.y,
                                          transformBasket.z)
            //hitNode.rotate(by: SCNQuaternion, aroundTarget: <#T##SCNVector3#>)
            
            print("\(transform.m31) \(transform.m32) \(transform.m33)")
        } else if sender.state == .ended || sender.state == .cancelled || sender.state == .failed {
            hoopMove = false
        }
        
    }
    
    
    @objc func handlePan(sender: UIPanGestureRecognizer){
        guard let sceneView = sender.view as? ARSCNView else {return}
        
        if (basketAdded && sender.state == .ended && hoopMove == false){
            let velocity = sender.velocity(in: sceneView)
            let translation = sender.translation(in: sceneView)
            shootBall(velocity: velocity, translation : translation)
        }
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])

        if !hitTestResult.isEmpty {
            if(!basketAdded){
                self.addBasket(hitTestResult: hitTestResult.first!)
                if(Globals.instance.isHosting){
                    
                    getAndSendWorldCoordinates(hitTestResult: hitTestResult.first!)
                }
            }
        }
    }
    
    func getAndSendWorldCoordinates(hitTestResult: ARHitTestResult){
        do{
            let tapPosition = hitTestResult.worldTransform.columns.3
            print(tapPosition)
            let encodablePosition = CodablePosition(dim1: tapPosition.x, dim2: tapPosition.y, dim3: tapPosition.z, dim4: tapPosition.w)
            let data : Data = try JSONEncoder().encode(encodablePosition)
            multipeerSession.sendToAllPeers(data)
        }
        catch{
            print("Was not able to encode position to data")
        }
    }

    //func addDetection()

    func addBasket(hitTestResult: ARHitTestResult) {
        if basketAdded == false {

            // Set backboard texture
            basketScene?.rootNode.childNode(withName: "backboard", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "backboard.jpg")
            
            basketScene?.rootNode.childNode(withName: "pole", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.gray

            let basketNode = basketScene?.rootNode.childNode(withName: "ball", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            let xPosition = positionOfPlane.x
            let yPosition = positionOfPlane.y
            let zPosition = positionOfPlane.z
            basketNode?.position = SCNVector3(xPosition,yPosition,zPosition)

            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
/*
            let detection = basketNode?.childNode(withName: "cylinder", recursively: false)
            let body2 = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: detection!))
            detection!.physicsBody = body2
            detection!.name = "detection"
            detection!.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
            detection!.physicsBody?.contactTestBitMask = CollisionCategory.ballCategory.rawValue
            detection?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            */
            /*
            let detection = basketNode?.childNode(withName: "cylinder", recursively: false)
            let body2 = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: detection!))
            detection!.physicsBody = body2
            detection!.name = "detection"
            detection!.physicsBody?.categoryBitMask = CollisionCategory.detectionCategory.rawValue
            detection!.physicsBody?.contactTestBitMask = CollisionCategory.ballCategory.rawValue
            */
            
            let anchor = ARAnchor(name: "basketAnchor", transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.basketAdded = true
            }
        }
    } // adds backboard and hoop to the scene view
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if(anchor.name == "basketAnchor" && !basketAdded){
            let basketNode = basketScene!.rootNode.childNode(withName: "ball", recursively: false)
            basketNode?.childNodes[3].physicsBody?.centerOfMassOffset = SCNVector3(0,0,0)
            let positionOfPlane = anchor.transform.columns.3
            print("BASKET POSITION \(positionOfPlane)")
            basketNode!.position = SCNVector3(positionOfPlane.x, positionOfPlane.y, positionOfPlane.z)
            basketNode?.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: basketNode!, options: [SCNPhysicsShape.Option.keepAsCompound: true, SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            basketAdded = true
            
            return basketNode
        }
        
        // check if anchor is one of the player anchors
        for (key, value) in playerPositionAnchors{
            if(anchor.name == key){ // we added an anchor in the scene that matches a player's name
                // need to add a node to show us where the anchor is
                let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
                ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture.png") // Set ball texture
                print(ball.position)
                let body = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: ball))
                ball.physicsBody = body
                ball.name = key
                body.restitution = 0.2
                return ball
            }
        }
        
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func shareSession(_ button: UIButton) {
        guard Globals.instance.isHosting else{ return }
        
        if(mapAvailable){
            sceneView.session.getCurrentWorldMap { worldMap, error in
                guard let map = worldMap
                    else { print("Error: \(error!.localizedDescription)"); return }
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    else { fatalError("can't encode map") }
                self.multipeerSession.sendToAllPeers(data)
                self.multipeerSession.advert.stopAdvertisingPeer()
                
                for peer in self.multipeerSession.connectedPeers{
                    guard let peerData = try? NSKeyedArchiver.archivedData(withRootObject: peer, requiringSecureCoding: true)
                        else { fatalError("can't encode peer list") }
                    self.multipeerSession.sendToAllPeers(peerData)
                }
            }
        }
    }
    
    func basketSyncHandler(worldMap: ARWorldMap, peerID: MCPeerID){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.initialWorldMap = worldMap
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        gameSetupState = .peerReceivedMap
        updateMultiPlayerStatus()
    }

    func dataHandler(_ data: Data, from peer: MCPeerID) {
        // get the ball from other player and add it to scene
        if let force : Float = data.withUnsafeBytes({ $0.pointee }){
            power = force
            print("got the force")
        }
        
        do{
            // if the data is a position, we need to sync our game world's position with that position
            let decodedData = try JSONDecoder().decode(CodablePosition.self, from: data)
            self.hostPosition = decodedData
        }
        catch{
        }
        
        do{
            // if the data is a position, we need to sync our game world's position with that position
            let decodedData = try JSONDecoder().decode(CodableTransform.self, from: data)
            
            let col0 = simd_float4(decodedData.col1.dim1, decodedData.col1.dim2, decodedData.col1.dim3, decodedData.col1.dim4)
            let col1 = simd_float4(decodedData.col2.dim1, decodedData.col2.dim2, decodedData.col2.dim3, decodedData.col2.dim4)
            let col2 = simd_float4(decodedData.col3.dim1, decodedData.col3.dim2, decodedData.col3.dim3, decodedData.col3.dim4)
            let col3 = simd_float4(decodedData.col4.dim1, decodedData.col4.dim2, decodedData.col4.dim3, decodedData.col4.dim4)
            
            let tform = simd_float4x4(col0, col1, col2, col3)
            let anchor = ARAnchor(name: decodedData.playerID, transform: tform)
            let anchorPos = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
//            let ourBasketPos = globalBasketNode!.position
//            let diffX = ourBasketPos.x - decodedData.basketPos.dim1
//            let diffY = ourBasketPos.y - decodedData.basketPos.dim2
//            let diffZ = ourBasketPos.z - decodedData.basketPos.dim3
            
            if(!playerPositionAnchors.isEmpty){
                if(playerPositionAnchors[decodedData.playerID] != nil){
                    sceneView.session.remove(anchor: playerPositionAnchors[decodedData.playerID]!)  // remove existing anchor from sceneview
                }
            }
            
            playerPositionAnchors[decodedData.playerID] = anchor
            sceneView.session.add(anchor: anchor)
            
//            let position = SCNVector3(anchorPos.x - diffX, anchorPos.y - diffY, anchorPos.z - diffZ)
            let position = anchorPos
            let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
            ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ballTexture.png") // Set ball texture
            ball.position = SCNVector3(position.x, position.y, position.z)
            print(ball.position)
            let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
            ball.physicsBody = body
            ball.name = peer.displayName
            body.restitution = 0.2
            
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
            // acknowledgement that everyone tapped the yellow points
            let decodedData = try JSONDecoder().decode(String.self, from: data)
            if(decodedData == "Tapped point"){
                numTappedPoints += 1
            }
            if(numTappedPoints == multipeerSession.connectedPeers.count){
                gameSetupState = .readyStatus
                updateMultiPlayerStatus()
                // CALL A FUNCTION TO GET UI UP FOR READY STATUS
            }
        }
        catch{
        }
        
        do{
            let decodedData = try JSONDecoder().decode(ArbitraryCodable.self, from: data)
            Globals.instance.scores[peer] = decodedData.score
        }
        catch{
            
        }
    }
    

    // called from ARSCNViewDelegate
    // SCNNode relating to a new anchor was added to the scene
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if(anchor is ARPlaneAnchor){
            DispatchQueue.main.async {
                self.planeDetected.isHidden = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.planeDetected.isHidden = true
            }
        }
        else if(anchor.name == "basketAnchor"){
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
    
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        let position = frame.camera.transform.columns.3
        //print("PlayerPosition: \(position)")
        playerPosition = CodablePosition(dim1: position.x, dim2: position.y, dim3: position.z, dim4: position.w)
        
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

    private func updateMultiPlayerStatus() {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch gameSetupState!{
        case .hostScanning:
            message = "Look around so we can get a map of the world. Once you're ready, send your map to everyone by pressing the button below."
        case .peerScanning:
            message = "Look around so we can get a map of the world. Wait for the host to send the map."
        case .hostSentMap:
            message = "Sent the world map to peers."
        case .peerReceivedMap:
            message = "Received world map from peers."
        case .everyoneTapPoint:
            message = "Everyone tap a yellow dot in the same location!"
        case .readyStatus:
            message = "Everyone has tapped a point."
            // MAKE POPUP TO ASK PLAYERS IF THEY'RE READY AND START GAME
            
        default:
            message = ""
        }
        
        DispatchQueue.main.async{
            self.multiPlayerStatus.text = message
            self.multiPlayerStatus.isHidden = message.isEmpty
        }
    }

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

extension SCNMatrix4 {
    static public func *(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
        let x = left.m11*right.x + left.m21*right.y + left.m31*right.z + left.m41*right.w
        let y = left.m12*right.x + left.m22*right.y + left.m32*right.z + left.m42*right.w
        let z = left.m13*right.x + left.m23*right.y + left.m33*right.z + left.m43*right.w
        let w = left.m14*right.x + left.m24*right.y + left.m43*right.z + left.m44*right.w
        
        return SCNVector4(x: x, y: y, z: z, w: w)
    }
}
