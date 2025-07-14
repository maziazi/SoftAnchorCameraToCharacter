//
//  GestureManager.swift
//  Canvas3DDragDrop
//
//  Created by Muhamad Azis on 23/06/25.
//

import UIKit
import RealityKit

class GestureManager {
    
    static func setupGestureRecognizers(_ arView: ARView, coordinator: CanvasCoordinator) {
        coordinator.arView = arView
        
        // Setup single tap gesture
        let tapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        arView.addGestureRecognizer(tapGesture)
        
        // Setup double tap gesture for camera switching
        let doubleTapGesture = UITapGestureRecognizer(target: coordinator, action: #selector(coordinator.handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        arView.addGestureRecognizer(doubleTapGesture)
        
        // Make sure single tap waits for double tap to fail
        tapGesture.require(toFail: doubleTapGesture)
        
        // Setup pan gesture
        let panGesture = UIPanGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        arView.addGestureRecognizer(panGesture)
        
        // Setup pinch gesture
        let pinchGesture = UIPinchGestureRecognizer(target: coordinator, action: #selector(coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Setup rotation gesture
        let rotationGesture = UIRotationGestureRecognizer(target: coordinator, action: #selector(coordinator.handleRotation(_:)))
        arView.addGestureRecognizer(rotationGesture)
        
        // Allow simultaneous gestures
        panGesture.delegate = coordinator
        pinchGesture.delegate = coordinator
        rotationGesture.delegate = coordinator
        
        print("Gesture recognizers setup complete with camera switching")
    }
}

// MARK: - Gesture Delegate
extension CanvasCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pinch and rotation to work together
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) ||
           (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        return false
    }
}
