//
//  RealityKitExtensions.swift
//  Canvas3DDragDrop
//
//  Created by Muhamad Azis on 23/06/25.
//

import RealityKit
import UIKit
import ARKit

class CanvasCoordinator: NSObject {
    var parent: RealityKitCanvasView
    var arView: ARView?
    var selectedEntity: ModelEntity?
    var selectionIndicator: Entity?
    var cameraEntity: PerspectiveCamera?
    var cameraAnchor: AnchorEntity?
    var gridAnchor: AnchorEntity?
    var allObjects: [Entity] = []
    
    // Camera control properties
    var cameraDistance: Float = 8.66
    var cameraVerticalAngle: Float = 0.615
    var cameraHorizontalAngle: Float = 0.785
    var canvasCenter = SIMD3<Float>(0, 0, 0)
    var cameraPosition = SIMD3<Float>(5, 5, 5)
    
    // Camera follow properties
    var cameraFollowTimer: Timer?
    var lastUserInteraction: Date = Date()
    private let followResumeDelay: TimeInterval = 2.0
    
    // ✨ NEW: Chair side movement properties
    var chairSideVelocity: Float = 0.0 // Current side velocity
    var chairTargetSideVelocity: Float = 0.0 // Target side velocity
    var chairSideDecay: Float = 0.95 // How quickly side movement decays
    var chairSideAcceleration: Float = 0.08 // How quickly chair reaches target velocity
    
    init(_ parent: RealityKitCanvasView) {
        self.parent = parent
        super.init()
        startCameraFollowUpdate()
    }
    
    deinit {
        stopCameraFollowUpdate()
    }
    
    // MARK: - Camera Follow Update System
    func startCameraFollowUpdate() {
        cameraFollowTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateCameraFollow()
            self?.updateChairSideMovement() // ✨ NEW: Update chair side movement
        }
    }
    
    func stopCameraFollowUpdate() {
        cameraFollowTimer?.invalidate()
        cameraFollowTimer = nil
    }
    
    func updateCameraFollow() {
        // Check if enough time has passed since last user interaction
        let timeSinceLastInteraction = Date().timeIntervalSince(lastUserInteraction)
        
        if timeSinceLastInteraction >= followResumeDelay && !UnifiedCameraManager.followEnabled && UnifiedCameraManager.isFollowMode() {
            UnifiedCameraManager.enableFollow()
        }
        
        // Update camera position (will handle current mode automatically)
        updateCameraPosition()
    }
    
    // ✨ NEW: Chair side movement update
    func updateChairSideMovement() {
        guard let kursi = allObjects.first(where: { $0.name == "kursi" }) else { return }
        
        // Smoothly interpolate current velocity toward target velocity
        chairSideVelocity = chairSideVelocity + (chairTargetSideVelocity - chairSideVelocity) * chairSideAcceleration
        
        // Apply side movement
        if abs(chairSideVelocity) > 0.001 {
            kursi.position.x += chairSideVelocity
        }
        
        // Apply decay to both velocities
        chairSideVelocity *= chairSideDecay
        chairTargetSideVelocity *= chairSideDecay
        
        // Stop very small movements
        if abs(chairSideVelocity) < 0.001 {
            chairSideVelocity = 0
        }
        if abs(chairTargetSideVelocity) < 0.001 {
            chairTargetSideVelocity = 0
        }
    }
    
    // MARK: - Gesture Handlers
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        // Check if tapping on an object
        if let entity = arView.entity(at: location) as? ModelEntity {
            print("Entity found: \(entity.name)")
            
            // Check if it's a valid selectable entity
            if entity.name != "GridFloor" &&
               entity.name != "SelectionIndicator" &&
               !entity.name.contains("WireBorder") &&
               !entity.name.contains("WireFrame") {
                selectedEntity = entity
                print("Selected entity: \(entity.name)")
                
                // Set as follow target if tapping on kursi
                if entity.name == "kursi" {
                    UnifiedCameraManager.setFollowTarget(entity)
                    print("Follow target set to: \(entity.name)")
                }
            }
        } else {
            print("No entity found at tap location")
            selectedEntity = nil
        }
    }
    
    // MARK: - Double Tap Handler for Camera Switching
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        UnifiedCameraManager.switchCameraMode(coordinator: self)
        print("Camera mode switched to: \(UnifiedCameraManager.getCurrentModeString())")
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let arView = arView else { return }
        
        let translation = gesture.translation(in: arView)
        let numberOfTouches = gesture.numberOfTouches
        
        // Mark user interaction untuk temporarily disable follow
        lastUserInteraction = Date()
        
        switch gesture.state {
        case .began:
            print("Pan began - touches: \(numberOfTouches), selected: \(selectedEntity?.name ?? "none"), camera mode: \(UnifiedCameraManager.getCurrentModeString())")
            
        case .changed:
            if let entity = selectedEntity, numberOfTouches == 1 {
                // Move selected object dengan 1 jari
                print("Moving selected object: \(entity.name)")
                moveSelectedObjectWithYAxis(translation: translation, in: arView)
                
                // Update follow target jika menggerakkan kursi
                if entity.name == "kursi" && UnifiedCameraManager.isFollowMode() {
                    UnifiedCameraManager.setFollowTarget(entity)
                }
            } else {
                if numberOfTouches == 1 {
                    // ✨ NEW: Handle chair side movement in follow mode
                    if UnifiedCameraManager.isFollowMode() {
                        handleChairSideMovement(translation: translation)
                    } else {
                        // Rotate canvas with one finger (mode-aware)
                        print("Rotating canvas with 1 finger - Mode: \(UnifiedCameraManager.getCurrentModeString())")
                        UnifiedCameraManager.rotateCanvas(translation: translation, coordinator: self)
                    }
                } else if numberOfTouches == 2 {
                    // Pan canvas with two fingers (mode-aware)
                    print("Panning canvas with 2 fingers - Mode: \(UnifiedCameraManager.getCurrentModeString())")
                    UnifiedCameraManager.panCanvas(translation: translation, coordinator: self)
                }
            }
            gesture.setTranslation(.zero, in: arView)
            
        case .ended, .cancelled:
            // Resume follow setelah gesture selesai (only in follow mode)
            if UnifiedCameraManager.isFollowMode() {
                DispatchQueue.main.asyncAfter(deadline: .now() + followResumeDelay) {
                    if Date().timeIntervalSince(self.lastUserInteraction) >= self.followResumeDelay {
                        UnifiedCameraManager.enableFollow()
                    }
                }
            }
            
        default:
            break
        }
        
        GridManager.updateGridPosition(coordinator: self)
    }
    
    // ✨ NEW: Handle chair side movement with horizontal swipe
    func handleChairSideMovement(translation: CGPoint) {
        let horizontalMovement = Float(translation.x)
        let verticalMovement = Float(translation.y)
        
        // Only respond to primarily horizontal movement
        if abs(horizontalMovement) > abs(verticalMovement) {
            let sideImpulse: Float = horizontalMovement * 0.002 // Adjust sensitivity
            
            // Add impulse to target velocity (accumulative for continuous swiping)
            chairTargetSideVelocity += sideImpulse
            
            // Limit maximum side velocity
            let maxSideVelocity: Float = 0.05
            chairTargetSideVelocity = max(-maxSideVelocity, min(maxSideVelocity, chairTargetSideVelocity))
            
            print("Chair side movement: \(sideImpulse > 0 ? "RIGHT" : "LEFT"), velocity: \(chairTargetSideVelocity)")
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let scale = Float(gesture.scale)
        
        // Mark user interaction
        lastUserInteraction = Date()
        
        if let entity = selectedEntity {
            // Scale selected object
            print("Scaling selected object: \(entity.name)")
            entity.scale = entity.scale * scale
        } else {
            // Zoom canvas (mode-aware)
            print("Zooming canvas - Mode: \(UnifiedCameraManager.getCurrentModeString())")
            UnifiedCameraManager.zoomCanvas(scale: scale, coordinator: self)
        }
        
        gesture.scale = 1.0
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        // Mark user interaction
        lastUserInteraction = Date()
        
        if let entity = selectedEntity {
            print("Rotating selected object: \(entity.name)")
            let rotation = Float(gesture.rotation)
            entity.orientation = simd_quatf(angle: rotation, axis: [0, 1, 0]) * entity.orientation
            gesture.rotation = 0
        }
    }
    
    func updateCameraPosition() {
        UnifiedCameraManager.updateCameraPosition(coordinator: self)
    }
    
    private func moveSelectedObjectWithYAxis(translation: CGPoint, in arView: ARView) {
        guard let entity = selectedEntity,
              let cameraEntity = cameraEntity else { return }
        
        let sensitivity: Float = 0.01
        
        // Get camera's right and up vectors
        let cameraTransform = cameraEntity.transform
        let cameraRight = normalize(SIMD3<Float>(cameraTransform.matrix.columns.0.x, 0, cameraTransform.matrix.columns.0.z))
        let cameraUp = SIMD3<Float>(0, 1, 0)
        
        // Horizontal movement (X and Z)
        let rightMovement = cameraRight * Float(translation.x) * sensitivity
        
        // Vertical movement (Y) - negative because screen Y is inverted
        let upMovement = cameraUp * Float(-translation.y) * sensitivity
        
        entity.position += rightMovement + upMovement
    }
    
    // MARK: - Camera Control Methods
    func switchCameraMode() {
        UnifiedCameraManager.switchCameraMode(coordinator: self)
    }
    
    func setCameraToOverviewMode() {
        UnifiedCameraManager.switchToOverviewMode(coordinator: self)
    }
    
    func setCameraToFollowMode() {
        UnifiedCameraManager.switchToFollowMode(coordinator: self)
    }
    
    func getCurrentCameraMode() -> String {
        return UnifiedCameraManager.getCurrentModeString()
    }
    
    func enableCameraFollow() {
        UnifiedCameraManager.enableFollow()
    }
    
    func disableCameraFollow() {
        UnifiedCameraManager.disableFollow()
    }
    
    func setCameraFollowTarget(_ target: Entity?) {
        UnifiedCameraManager.setFollowTarget(target)
    }
}
