//
//  RealityKitCanvasView.swift
//  Canvas3DDragDrop
//
//  Created by Muhamad Azis on 23/06/25.
//

import SwiftUI
import RealityKit
import ARKit

struct RealityKitCanvasView: UIViewRepresentable {
    @Binding var placedObjects: [Entity]
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        
        // Setup scene
        setupScene(arView, coordinator: context.coordinator)
        
        // Setup gesture recognizers (includes double tap for camera switching)
        GestureManager.setupGestureRecognizers(arView, coordinator: context.coordinator)
        
        // Load room automatically when view is created
        loadRoomFromResources(arView, coordinator: context.coordinator)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Add new objects to scene
        for object in placedObjects {
            if object.parent == nil {
                // Check if this is a room object
                if object.name == "room" || object.name == "fallback_room" {
                    // Place room at exact center (0, 0, 0)
                    object.position = SIMD3<Float>(0, 0, 0)
                } else {
                    // Calculate center position and stack other objects
                    let centerPosition = calculateCenterPosition(for: object, in: uiView, existingObjects: context.coordinator.allObjects)
                    object.position = centerPosition
                }
                
                uiView.scene.addAnchor(createAnchorEntity(with: object))
                
                // Store reference to coordinator for later access
                context.coordinator.allObjects.append(object)
                
                // Auto-set kursi as follow target
                if object.name == "kursi" {
                    UnifiedCameraManager.setFollowTarget(object)
                    print("Auto-set kursi as follow target")
                }
            }
        }
    }
    
    func makeCoordinator() -> CanvasCoordinator {
        CanvasCoordinator(self)
    }
    
    // MARK: - Room Loading Functions
    
    /// Load room.usdz from resources automatically
    private func loadRoomFromResources(_ arView: ARView, coordinator: CanvasCoordinator) {
        Task {
            await loadRoomAsync(arView, coordinator: coordinator)
        }
    }
    
    /// Asynchronously load room from bundle
    private func loadRoomAsync(_ arView: ARView, coordinator: CanvasCoordinator) async {
        do {
            // Try to load room.usdz from bundle
            guard let roomURL = Bundle.main.url(forResource: "room", withExtension: "usdz", subdirectory: "resources/room") else {
                print("Room.usdz not found in resources/room/, creating fallback room")
                return
            }
            
            let loadedRoom = try await ModelEntity(contentsOf: roomURL)
            
            await MainActor.run {
                // Configure room entity
                loadedRoom.name = "room"
                loadedRoom.generateCollisionShapes(recursive: true)
                
                // Position room at center
                loadedRoom.position = SIMD3<Float>(0, 0, 0)
                
                // Add to scene
                let roomAnchor = AnchorEntity()
                roomAnchor.addChild(loadedRoom)
                arView.scene.addAnchor(roomAnchor)
                
                // Store in coordinator
                coordinator.allObjects.append(loadedRoom)
                
                print("Room.usdz loaded successfully at center")
            }
        } catch {
            print("Failed to load room.usdz: \(error)")
        }
    }

    
    // MARK: - Center Positioning Functions
    
    /// Calculate center position for new object, stacking above existing objects
    private func calculateCenterPosition(for newObject: Entity, in arView: ARView, existingObjects: [Entity]) -> SIMD3<Float> {
        let basePosition = SIMD3<Float>(0, 0, 0) // Center of the world
        
        // Filter out room objects from stacking calculation
        let nonRoomObjects = existingObjects.filter { object in
            object.name != "room" && object.name != "fallback_room"
        }
        
        // If no existing non-room objects, place at base height
        if nonRoomObjects.isEmpty {
            return SIMD3<Float>(basePosition.x, getObjectHeight(newObject) / 2, basePosition.z)
        }
        
        // Find the highest non-room object at center position
        let centerObjects = nonRoomObjects.filter { object in
            let distance = simd_distance(SIMD2<Float>(object.position.x, object.position.z),
                                       SIMD2<Float>(basePosition.x, basePosition.z))
            return distance < 0.5 // Objects within 0.5 units of center
        }
        
        if centerObjects.isEmpty {
            // No objects at center, place at base height
            return SIMD3<Float>(basePosition.x, getObjectHeight(newObject) / 2, basePosition.z)
        } else {
            // Stack above the highest object
            let highestY = centerObjects.map { $0.position.y + getObjectHeight($0) / 2 }.max() ?? 0
            let newY = highestY + getObjectHeight(newObject) / 2 + 0.1 // Add small gap
            return SIMD3<Float>(basePosition.x, newY, basePosition.z)
        }
    }
    
    /// Get approximate height of an object
    private func getObjectHeight(_ object: Entity) -> Float {
        // Try to get actual bounds
        if let modelEntity = object as? ModelEntity,
           let mesh = modelEntity.model?.mesh {
            return mesh.bounds.max.y - mesh.bounds.min.y
        }
        
        // Fallback to default height
        return 0.2
    }
    
    /// Place object at exact center of canvas
    func placeObjectAtCenter(_ object: Entity, in arView: ARView) {
        let centerPosition = SIMD3<Float>(0, getObjectHeight(object) / 2, 0)
        object.position = centerPosition
        
        let anchor = createAnchorEntity(with: object)
        arView.scene.addAnchor(anchor)
    }
    
    /// Stack object above all objects at center
    func stackObjectAtCenter(_ object: Entity, in arView: ARView, existingObjects: [Entity]) {
        let position = calculateCenterPosition(for: object, in: arView, existingObjects: existingObjects)
        object.position = position
        
        let anchor = createAnchorEntity(with: object)
        arView.scene.addAnchor(anchor)
    }
    
    private func setupScene(_ arView: ARView, coordinator: CanvasCoordinator) {
        // Create infinite grid floors
        GridManager.createInfiniteGridFloor(arView, coordinator: coordinator)
        
        // Setup lighting
        setupLighting(arView)
        
        // Setup unified camera system
        UnifiedCameraManager.setupCamera(arView, coordinator: coordinator)
        
        // Set gray background
        arView.environment.background = .color(.systemGray5)
    }
    
    private func setupLighting(_ arView: ARView) {
        // Add directional light
        let directionalLight = DirectionalLight()
        directionalLight.light.intensity = 2000
        directionalLight.orientation = simd_quatf(angle: -.pi/4, axis: [1, 1, 0])
        
        let lightAnchor = AnchorEntity()
        lightAnchor.addChild(directionalLight)
        arView.scene.addAnchor(lightAnchor)
        
        // Add ambient light
        let ambientLight = DirectionalLight()
        ambientLight.light.intensity = 500
        ambientLight.light.color = .white
        lightAnchor.addChild(ambientLight)
    }
    
    private func createAnchorEntity(with entity: Entity) -> AnchorEntity {
        let anchor = AnchorEntity()
        anchor.addChild(entity)
        return anchor
    }
}
