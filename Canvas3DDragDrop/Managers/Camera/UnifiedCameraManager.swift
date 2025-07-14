//
//  UnifiedCameraManager.swift
//  SoftAnchorCameraToCharacter
//
//  Created by Muhamad Azis on 14/07/25.
//

import Foundation
import RealityKit
import ARKit
import simd

enum CameraMode {
    case overview    // Free camera untuk melihat semua object
    case follow      // Camera mengikuti object tertentu
}

class UnifiedCameraManager {
    
    // MARK: - Camera Mode Properties
    static var currentMode: CameraMode = .overview
    static var previousMode: CameraMode = .overview
    
    // MARK: - Overview Camera Properties (Original CameraManager)
    static var overviewCameraDistance: Float = 8.66
    static var overviewVerticalAngle: Float = 0.615
    static var overviewHorizontalAngle: Float = 1.5708
    static var overviewCanvasCenter = SIMD3<Float>(0, 0, 0)
    
    // MARK: - Follow Camera Properties (CameraFollowManager)
    static var followTarget: Entity?
    static var followEnabled: Bool = true
    static var followSmoothness: Float = 0.05
    static var followOffset: SIMD3<Float> = SIMD3<Float>(3, 2, 3)
    static var followCanvasCenter: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    static var followCameraDistance: Float = 5.0
    static var followVerticalAngle: Float = 0.3
    static var followHorizontalAngle: Float = 1.5708
    
    // MARK: - Camera Setup
    static func setupCamera(_ arView: ARView, coordinator: CanvasCoordinator) {
        let cameraEntity = PerspectiveCamera()
        let cameraAnchor = AnchorEntity()
        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)
        
        coordinator.cameraEntity = cameraEntity
        coordinator.cameraAnchor = cameraAnchor
        
        // Initialize dengan overview mode
        switchToOverviewMode(coordinator: coordinator)
    }
    
    // MARK: - Camera Mode Switching
    static func switchCameraMode(coordinator: CanvasCoordinator) {
        previousMode = currentMode
        
        switch currentMode {
        case .overview:
            switchToFollowMode(coordinator: coordinator)
        case .follow:
            switchToOverviewMode(coordinator: coordinator)
        }
        
        print("Camera switched from \(previousMode) to \(currentMode)")
    }
    
    static func switchToOverviewMode(coordinator: CanvasCoordinator) {
        currentMode = .overview
        
        // Restore overview camera properties
        coordinator.cameraDistance = overviewCameraDistance
        coordinator.cameraVerticalAngle = overviewVerticalAngle
        coordinator.cameraHorizontalAngle = overviewHorizontalAngle
        coordinator.canvasCenter = overviewCanvasCenter
        
        updateCameraPosition(coordinator: coordinator)
        print("Switched to Overview Mode")
    }
    
    static func switchToFollowMode(coordinator: CanvasCoordinator) {
        // Save current overview state
        saveOverviewState(coordinator: coordinator)
        
        currentMode = .follow
        
        // Setup follow mode
        if let target = followTarget {
            followCanvasCenter = SIMD3<Float>(target.position.x, 0, target.position.z)
        }
        
        coordinator.cameraDistance = followCameraDistance
        coordinator.cameraVerticalAngle = followVerticalAngle
        coordinator.cameraHorizontalAngle = followHorizontalAngle
        coordinator.canvasCenter = followCanvasCenter
        
        updateCameraPosition(coordinator: coordinator)
        print("Switched to Follow Mode - Target: \(followTarget?.name ?? "none")")
    }
    
    static func saveOverviewState(coordinator: CanvasCoordinator) {
        overviewCameraDistance = coordinator.cameraDistance
        overviewVerticalAngle = coordinator.cameraVerticalAngle
        overviewHorizontalAngle = coordinator.cameraHorizontalAngle
        overviewCanvasCenter = coordinator.canvasCenter
    }
    
    // MARK: - Camera Position Update
    static func updateCameraPosition(coordinator: CanvasCoordinator) {
        guard let cameraEntity = coordinator.cameraEntity else { return }
        
        switch currentMode {
        case .overview:
            updateOverviewCamera(coordinator: coordinator)
        case .follow:
            updateFollowCamera(coordinator: coordinator)
        }
    }
    
    private static func updateOverviewCamera(coordinator: CanvasCoordinator) {
        guard let cameraEntity = coordinator.cameraEntity else { return }
        
        let x = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * cos(coordinator.cameraHorizontalAngle)
        let y = coordinator.cameraDistance * sin(coordinator.cameraVerticalAngle)
        let z = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * sin(coordinator.cameraHorizontalAngle)
        
        coordinator.cameraPosition = coordinator.canvasCenter + SIMD3<Float>(x, y, z)
        
        cameraEntity.position = coordinator.cameraPosition
        cameraEntity.look(at: coordinator.canvasCenter, from: coordinator.cameraPosition, relativeTo: nil)
    }
    
    private static func updateFollowCamera(coordinator: CanvasCoordinator) {
        guard let cameraEntity = coordinator.cameraEntity else { return }
        
        // Update follow target position
        updateFollowTarget(coordinator: coordinator)
        
        let x = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * cos(coordinator.cameraHorizontalAngle)
        let y = coordinator.cameraDistance * sin(coordinator.cameraVerticalAngle)
        let z = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * sin(coordinator.cameraHorizontalAngle)
        
        coordinator.cameraPosition = coordinator.canvasCenter + SIMD3<Float>(x, y, z)
        
        cameraEntity.position = coordinator.cameraPosition
        cameraEntity.look(at: coordinator.canvasCenter, from: coordinator.cameraPosition, relativeTo: nil)
    }
    
    private static func updateFollowTarget(coordinator: CanvasCoordinator) {
        guard followEnabled, let target = followTarget else { return }
        
        // Calculate desired canvas center based on target position
        let targetPosition = target.position + followOffset
        let targetCanvasCenter = SIMD3<Float>(targetPosition.x, 0, targetPosition.z)
        
        // Smooth interpolation ke target position
        let currentCenter = coordinator.canvasCenter
        let smoothedCenter = mix(currentCenter, targetCanvasCenter, t: followSmoothness)
        
        coordinator.canvasCenter = smoothedCenter
        followCanvasCenter = coordinator.canvasCenter
    }
    
    // MARK: - Gesture Controls (Mode-aware)
    static func rotateCanvas(translation: CGPoint, coordinator: CanvasCoordinator) {
        switch currentMode {
        case .overview:
            rotateOverviewCamera(translation: translation, coordinator: coordinator)
        case .follow:
            rotateFollowCamera(translation: translation, coordinator: coordinator)
        }
    }
    
    private static func rotateOverviewCamera(translation: CGPoint, coordinator: CanvasCoordinator) {
        let sensitivity: Float = 0.01
        
        if abs(translation.x) > abs(translation.y) {
            coordinator.cameraHorizontalAngle += Float(translation.x) * sensitivity
        } else {
            coordinator.cameraVerticalAngle -= Float(translation.y) * sensitivity
            coordinator.cameraVerticalAngle = max(-Float.pi/2 + 0.1, min(Float.pi/2 - 0.1, coordinator.cameraVerticalAngle))
        }
        
        updateCameraPosition(coordinator: coordinator)
    }
    
    private static func rotateFollowCamera(translation: CGPoint, coordinator: CanvasCoordinator) {
        // Temporarily disable follow untuk manual control
        temporarilyDisableFollow()
        
        let sensitivity: Float = 0.008 // Sedikit lebih sensitif untuk follow mode
        
        if abs(translation.x) > abs(translation.y) {
            coordinator.cameraHorizontalAngle += Float(translation.x) * sensitivity
        } else {
            coordinator.cameraVerticalAngle -= Float(translation.y) * sensitivity
            coordinator.cameraVerticalAngle = max(-Float.pi/2 + 0.1, min(Float.pi/2 - 0.1, coordinator.cameraVerticalAngle))
        }
        
        updateCameraPosition(coordinator: coordinator)
    }
    
    static func panCanvas(translation: CGPoint, coordinator: CanvasCoordinator) {
        guard let cameraEntity = coordinator.cameraEntity else { return }
        
        switch currentMode {
        case .overview:
            panOverviewCamera(translation: translation, coordinator: coordinator, cameraEntity: cameraEntity)
        case .follow:
            panFollowCamera(translation: translation, coordinator: coordinator, cameraEntity: cameraEntity)
        }
    }
    
    private static func panOverviewCamera(translation: CGPoint, coordinator: CanvasCoordinator, cameraEntity: PerspectiveCamera) {
        let sensitivity: Float = 0.02
        
        let cameraTransform = cameraEntity.transform
        let cameraRight = normalize(SIMD3<Float>(cameraTransform.matrix.columns.0.x, 0, cameraTransform.matrix.columns.0.z))
        let cameraForward = normalize(SIMD3<Float>(-cameraTransform.matrix.columns.2.x, 0, -cameraTransform.matrix.columns.2.z))
        
        let rightMovement = cameraRight * Float(-translation.x) * sensitivity
        let forwardMovement = cameraForward * Float(translation.y) * sensitivity
        
        coordinator.canvasCenter += rightMovement + forwardMovement
        
        updateCameraPosition(coordinator: coordinator)
    }
    
    private static func panFollowCamera(translation: CGPoint, coordinator: CanvasCoordinator, cameraEntity: PerspectiveCamera) {
        // Temporarily disable follow untuk manual control
        temporarilyDisableFollow()
        
        let sensitivity: Float = 0.015 // Sedikit kurang sensitif untuk follow mode
        
        let cameraTransform = cameraEntity.transform
        let cameraRight = normalize(SIMD3<Float>(cameraTransform.matrix.columns.0.x, 0, cameraTransform.matrix.columns.0.z))
        let cameraForward = normalize(SIMD3<Float>(-cameraTransform.matrix.columns.2.x, 0, -cameraTransform.matrix.columns.2.z))
        
        let rightMovement = cameraRight * Float(-translation.x) * sensitivity
        let forwardMovement = cameraForward * Float(translation.y) * sensitivity
        
        coordinator.canvasCenter += rightMovement + forwardMovement
        
        updateCameraPosition(coordinator: coordinator)
    }
    
    static func zoomCanvas(scale: Float, coordinator: CanvasCoordinator) {
        let minDistance: Float = currentMode == .follow ? 1.0 : 2.0
        let maxDistance: Float = currentMode == .follow ? 20.0 : 50.0
        
        coordinator.cameraDistance = max(minDistance, min(maxDistance, coordinator.cameraDistance / scale))
        updateCameraPosition(coordinator: coordinator)
    }
    
    // MARK: - Follow Target Management
    static func setFollowTarget(_ target: Entity?) {
        followTarget = target
        if let target = target {
            print("Follow target set: \(target.name)")
            // Auto switch to follow mode if not already
            if currentMode == .overview {
                // Don't auto switch, let user decide
            }
        } else {
            print("Follow target cleared")
        }
    }
    
    static func enableFollow() {
        followEnabled = true
        print("Camera follow enabled")
    }
    
    static func disableFollow() {
        followEnabled = false
        print("Camera follow disabled")
    }
    
    static func temporarilyDisableFollow() {
        if currentMode == .follow {
            followEnabled = false
            // Re-enable setelah delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if currentMode == .follow {
                    followEnabled = true
                }
            }
        }
    }
    
    static func setFollowSmoothness(_ smoothness: Float) {
        followSmoothness = max(0.01, min(0.5, smoothness))
    }
    
    static func setFollowOffset(_ offset: SIMD3<Float>) {
        followOffset = offset
    }
    
    // MARK: - Quick Access Functions
    static func isOverviewMode() -> Bool {
        return currentMode == .overview
    }
    
    static func isFollowMode() -> Bool {
        return currentMode == .follow
    }
    
    static func getCurrentModeString() -> String {
        switch currentMode {
        case .overview: return "Overview"
        case .follow: return "Follow"
        }
    }
}

// MARK: - Helper Extensions
//extension SIMD3 where Scalar == Float {
//    func mix(_ other: SIMD3<Float>, t: Float) -> SIMD3<Float> {
//        return self + (other - self) * t
//    }
//}
//
//func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
//    return a + (b - a) * t
//}
