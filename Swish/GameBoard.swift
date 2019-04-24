//
//  GameBoard.swift
//  Swish
//
//  Taken from Apple SwiftShot source code
//

/*
Abstract:
Manages placement of the game board in real space before starting a game.
*/

import Foundation
import ARKit

/// GameBoard represents the physical surface which the game is played upon.
/// In this node's child coordinate space, coordinates are normalized to the
/// board's width. So if the user wants to see the game appear in worldspace 1.5 meters
/// wide, the scale portion of this node's transform will be 1.5 in all dimensions.
class GameBoard: SCNNode {
    // MARK: - Configuration Properties
    /// The minimum size of the board in meters
    static let minimumScale: Float = 0.5
    
    /// The maximum size of the board in meters
    static let maximumScale: Float = 2.0
    
    /// Duration of the open/close animation
    static let animationDuration = 0.7
    
    // MARK: - Properties
    /// The BoardAnchor in the scene
    var anchor: BoardAnchor?
    
    /// Indicates whether the border is currently hidden
    var isBorderHidden: Bool {
        return borderNode.isHidden || borderNode.action(forKey: "hide") != nil
    }
    
    /// The level's preferred size.
    /// This is used both to set the aspect ratio and to determine
    /// the default size.
    var preferredSize: CGSize = CGSize(width: 1.5, height: 2.7) 
    
    /// The aspect ratio of the level.
    var aspectRatio: Float { return Float(preferredSize.height / preferredSize.width) }
    
    /// Indicates whether the segments of the border are disconnected.
    private var isBorderOpen = false
    
    /// Indicates if the game board is currently being animated.
    private var isAnimating = false
    
    /// The game board's most recent positions.
    private var recentPositions: [float3] = []
    
    /// The game board's most recent rotation angles.
    private var recentRotationAngles: [Float] = []
    
    /// Previously visited plane anchors.
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    
    /// The node used to visualize the game border.
    private let borderNode = SCNNode()
    
    /// List of the segments in the border.
    
    // MARK: - Initialization
    override init() {
        super.init()
        
        // Set initial game board scale
        simdScale = float3(GameBoard.minimumScale)
        
        // Orient border to XZ plane and set aspect ratio
        borderNode.eulerAngles.x = .pi / 2
        borderNode.isHidden = true
        
        addChildNode(borderNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: - Appearance
    /// Hides the border.
    func hideBorder(duration: TimeInterval = 0.5) {
        guard borderNode.action(forKey: "hide") == nil else { return }
        
        borderNode.removeAction(forKey: "unhide")
        borderNode.runAction(.fadeOut(duration: duration), forKey: "hide") {
            self.borderNode.isHidden = true
        }
    }
    
    /// Unhides the border.
    func unhideBorder() {
        guard borderNode.action(forKey: "unhide") == nil else { return }
        
        borderNode.removeAction(forKey: "hide")
        borderNode.runAction(.fadeIn(duration: 0.5), forKey: "unhide")
        borderNode.isHidden = false
    }
    
    /// Updates the game board with the latest hit test result and camera.
    func update(with hitTestResult: ARHitTestResult, camera: ARCamera) {
        if isBorderHidden {
            unhideBorder()
        }
        
        if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
            anchorsOfVisitedPlanes.insert(planeAnchor)
        }
        
        updateTransform(with: hitTestResult, camera: camera)
    }
    
    func reset() {
        borderNode.removeAllActions()
        borderNode.isHidden = true
        recentPositions.removeAll()
        recentRotationAngles.removeAll()
        isHidden = false
    }
    
    /// Incrementally scales the board by the given amount
    func scale(by factor: Float) {
        // assumes we always scale the same in all 3 dimensions
        let currentScale = simdScale.x
        let newScale = clamp(currentScale * factor, GameBoard.minimumScale, GameBoard.maximumScale)
        simdScale = float3(newScale)
    }
    
    func useDefaultScale() {
        let scale = preferredSize.width
        simdScale = float3(Float(scale))
    }
    
    // MARK: Helper Methods
    /// Update the transform of the game board with the latest hit test result and camera
    private func updateTransform(with hitTestResult: ARHitTestResult, camera: ARCamera) {
        let position = hitTestResult.worldTransform.translation
        
        // Average using several most recent positions.
        recentPositions.append(position)
        recentPositions = Array(recentPositions.suffix(10))
        
        // Move to average of recent positions to avoid jitter.
        let average = recentPositions.reduce(float3(0), { $0 + $1 }) / Float(recentPositions.count)
        simdPosition = average
        
        // Orient bounds to plane if possible
        if let planeAnchor = hitTestResult.anchor as? ARPlaneAnchor {
            orientToPlane(planeAnchor, camera: camera)
            scaleToPlane(planeAnchor)
        } else {
            // Fall back to camera orientation
            orientToCamera(camera)
            simdScale = float3(GameBoard.minimumScale)
        }
        
        // Remove any animation duration if present
        SCNTransaction.animationDuration = 0
    }
    
    private func orientToCamera(_ camera: ARCamera) {
        rotate(to: camera.eulerAngles.y)
    }
    
    private func orientToPlane(_ planeAnchor: ARPlaneAnchor, camera: ARCamera) {
        // Get board rotation about y
        simdOrientation = simd_quatf(planeAnchor.transform)
        var boardAngle = simdEulerAngles.y
        
        // If plane is longer than deep, rotate 90 degrees
        if planeAnchor.extent.x > planeAnchor.extent.z {
            boardAngle += .pi / 2
        }
        
        // Normalize angle to closest 180 degrees to camera angle
        boardAngle = boardAngle.normalizedAngle(forMinimalRotationTo: camera.eulerAngles.y, increment: .pi)
        
        rotate(to: boardAngle)
    }
    
    private func rotate(to angle: Float) {
        // Avoid interpolating between angle flips of 180 degrees
        let previouAngle = recentRotationAngles.reduce(0, { $0 + $1 }) / Float(recentRotationAngles.count)
        if abs(angle - previouAngle) > .pi / 2 {
            recentRotationAngles = recentRotationAngles.map { $0.normalizedAngle(forMinimalRotationTo: angle, increment: .pi) }
        }
        
        // Average using several most recent rotation angles.
        recentRotationAngles.append(angle)
        recentRotationAngles = Array(recentRotationAngles.suffix(20))
        
        // Move to average of recent positions to avoid jitter.
        let averageAngle = recentRotationAngles.reduce(0, { $0 + $1 }) / Float(recentRotationAngles.count)
        simdRotation = float4(0, 1, 0, averageAngle)
    }
    
    private func scaleToPlane(_ planeAnchor: ARPlaneAnchor) {
        // Determine if extent should be flipped (plane is 90 degrees rotated)
        let planeXAxis = planeAnchor.transform.columns.0.xyz
        let axisFlipped = abs(dot(planeXAxis, simdWorldRight)) < 0.5
        
        // Flip dimensions if necessary
        var planeExtent = planeAnchor.extent
        if axisFlipped {
            planeExtent = vector3(planeExtent.z, 0, planeExtent.x)
        }
        
        // Scale board to the max extent that fits in the plane
        var width = min(planeExtent.x, GameBoard.maximumScale)
        let depth = min(planeExtent.z, width * aspectRatio)
        width = depth / aspectRatio
        simdScale = float3(width)
        
        // Adjust position of board within plane's bounds
        var planeLocalExtent = float3(width, 0, depth)
        if axisFlipped {
            planeLocalExtent = vector3(planeLocalExtent.z, 0, planeLocalExtent.x)
        }
        adjustPosition(withinPlaneBounds: planeAnchor, extent: planeLocalExtent)
    }
    
    private func adjustPosition(withinPlaneBounds planeAnchor: ARPlaneAnchor, extent: float3) {
        var positionAdjusted = false
        let worldToPlane = planeAnchor.transform.inverse
        
        // Get current position in the local plane coordinate space
        var planeLocalPosition = (worldToPlane * simdTransform.columns.3)
        
        // Compute bounds min and max
        let boardMin = planeLocalPosition.xyz - extent / 2
        let boardMax = planeLocalPosition.xyz + extent / 2
        let planeMin = planeAnchor.center - planeAnchor.extent / 2
        let planeMax = planeAnchor.center + planeAnchor.extent / 2
        
        // Adjust position for x within plane bounds
        if boardMin.x < planeMin.x {
            planeLocalPosition.x += planeMin.x - boardMin.x
            positionAdjusted = true
        } else if boardMax.x > planeMax.x {
            planeLocalPosition.x -= boardMax.x - planeMax.x
            positionAdjusted = true
        }
        
        // Adjust position for z within plane bounds
        if boardMin.z < planeMin.z {
            planeLocalPosition.z += planeMin.z - boardMin.z
            positionAdjusted = true
        } else if boardMax.z > planeMax.z {
            planeLocalPosition.z -= boardMax.z - planeMax.z
            positionAdjusted = true
        }
        
        if positionAdjusted {
            simdPosition = (planeAnchor.transform * planeLocalPosition).xyz
        }
    }
}

extension float4x4 {
    var translation: float3 {
        get {
            return columns.3.xyz
        }
        set(newValue) {
            columns.3 = float4(newValue, 1)
        }
    }
}

extension float4 {
    var xyz: float3 {
        get {
            return float3(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    init(_ xyz: float3, _ w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
}

extension Float {
    func normalizedAngle(forMinimalRotationTo angle: Float, increment: Float) -> Float {
        var normalized = self
        while abs(normalized - angle) > increment / 2 {
            if self > angle {
                normalized -= increment
            } else {
                normalized += increment
            }
        }
        return normalized
    }
}
