//
//  CameraFollowManager.swift
//  SoftAnchorCameraToCharacter
//
//  Created by Muhamad Azis on 14/07/25.
//

import Foundation
import RealityKit
import ARKit
import simd

class CameraFollowManager {
    
    // MARK: - Camera Follow Properties
    static var followTarget: Entity?
    static var followEnabled: Bool = true
    static var followSmoothness: Float = 0.05 // Kecepatan interpolasi (0.01 = sangat halus, 0.1 = cepat)
    static var followOffset: SIMD3<Float> = SIMD3<Float>(0, 2, 3) // Offset dari target
    static var targetCanvasCenter: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    static func setupCamera(_ arView: ARView, coordinator: CanvasCoordinator) {
        let cameraEntity = PerspectiveCamera()
        let cameraAnchor = AnchorEntity()
        cameraAnchor.addChild(cameraEntity)
        arView.scene.addAnchor(cameraAnchor)
        
        coordinator.cameraEntity = cameraEntity
        coordinator.cameraAnchor = cameraAnchor
        
        coordinator.updateCameraPosition()
    }
    
    static func updateCameraPosition(coordinator: CanvasCoordinator) {
        guard let cameraEntity = coordinator.cameraEntity else { return }
        
        // Update target position berdasarkan follow target
        updateFollowTarget(coordinator: coordinator)
        
        let x = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * cos(coordinator.cameraHorizontalAngle)
        let y = coordinator.cameraDistance * sin(coordinator.cameraVerticalAngle)
        let z = coordinator.cameraDistance * cos(coordinator.cameraVerticalAngle) * sin(coordinator.cameraHorizontalAngle)
        
        coordinator.cameraPosition = coordinator.canvasCenter + SIMD3<Float>(x, y, z)
        
        cameraEntity.position = coordinator.cameraPosition
        cameraEntity.look(at: coordinator.canvasCenter, from: coordinator.cameraPosition, relativeTo: nil)
    }
    
    // MARK: - Follow Target System
    static func setFollowTarget(_ target: Entity?) {
        followTarget = target
        if let target = target {
            print("Camera now following: \(target.name)")
        } else {
            print("Camera follow disabled")
        }
    }
    
    static func updateFollowTarget(coordinator: CanvasCoordinator) {
        guard followEnabled, let target = followTarget else { return }
        
        // Calculate desired canvas center based on target position and offset
        let targetPosition = target.position + followOffset
        targetCanvasCenter = SIMD3<Float>(targetPosition.x, 0, targetPosition.z)
        
        // Smooth interpolation ke target position
        let currentCenter = coordinator.canvasCenter
        let smoothedCenter = mix(currentCenter, targetCanvasCenter, t: followSmoothness)
        
        coordinator.canvasCenter = smoothedCenter
    }
    
    // MARK: - Original Camera Controls (Modified)
    static func rotateCanvas(translation: CGPoint, coordinator: CanvasCoordinator) {
        // Disable follow saat user manual control
        temporarilyDisableFollow()
        
        let sensitivity: Float = 0.01
        
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
        
        // Disable follow saat user manual control
        temporarilyDisableFollow()
        
        let sensitivity: Float = 0.02
        
        let cameraTransform = cameraEntity.transform
        let cameraRight = normalize(SIMD3<Float>(cameraTransform.matrix.columns.0.x, 0, cameraTransform.matrix.columns.0.z))
        let cameraForward = normalize(SIMD3<Float>(-cameraTransform.matrix.columns.2.x, 0, -cameraTransform.matrix.columns.2.z))
        
        let rightMovement = cameraRight * Float(-translation.x) * sensitivity
        let forwardMovement = cameraForward * Float(translation.y) * sensitivity
        
        coordinator.canvasCenter += rightMovement + forwardMovement
        
        updateCameraPosition(coordinator: coordinator)
    }
    
    static func zoomCanvas(scale: Float, coordinator: CanvasCoordinator) {
        coordinator.cameraDistance = max(2.0, min(50.0, coordinator.cameraDistance / scale))
        updateCameraPosition(coordinator: coordinator)
    }
    
    // MARK: - Follow Control Methods
    static func enableFollow() {
        followEnabled = true
        print("Camera follow enabled")
    }
    
    static func disableFollow() {
        followEnabled = false
        print("Camera follow disabled")
    }
    
    static func temporarilyDisableFollow() {
        followEnabled = false
        // Re-enable setelah delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            followEnabled = true
        }
    }
    
    static func setFollowSmoothness(_ smoothness: Float) {
        followSmoothness = max(0.01, min(0.5, smoothness))
    }
    
    static func setFollowOffset(_ offset: SIMD3<Float>) {
        followOffset = offset
    }
}

// MARK: - Helper Extensions
extension SIMD3 where Scalar == Float {
    func mix(_ other: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return self + (other - self) * t
    }
}

func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
    return a + (b - a) * t
}
