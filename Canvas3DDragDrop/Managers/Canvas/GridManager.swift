//
//  GridManager.swift
//  Canvas3DDragDrop
//
//  Created by Muhamad Azis on 23/06/25.
//

import Foundation
import RealityKit
import ARKit

class GridManager {
    
    static func createInfiniteGridFloor(_ arView: ARView, coordinator: CanvasCoordinator) {
        let tileSize: Float = 50.0
        let numTiles = 21
        let offset = Float(numTiles / 2) * tileSize
        
        let gridAnchor = AnchorEntity()
        coordinator.gridAnchor = gridAnchor
        
        for x in 0..<numTiles {
            for z in 0..<numTiles {
                let gridTile = createGridTile(size: tileSize)
                gridTile.position = SIMD3<Float>(
                    Float(x) * tileSize - offset,
                    0,
                    Float(z) * tileSize - offset
                )
                gridAnchor.addChild(gridTile)
            }
        }
        
        arView.scene.addAnchor(gridAnchor)
    }
    
    static func updateGridPosition(coordinator: CanvasCoordinator) {
        guard let gridAnchor = coordinator.gridAnchor else { return }
        
        let gridSize: Float = 50.0
        let offsetX = round(coordinator.canvasCenter.x / gridSize) * gridSize
        let offsetZ = round(coordinator.canvasCenter.z / gridSize) * gridSize
        
        gridAnchor.position = SIMD3<Float>(offsetX, 0, offsetZ)
    }
    
    private static func createGridTile(size: Float) -> ModelEntity {
        let gridTexture = TextureGenerator.createGrayGridTexture()
        
        guard let textureResource = try? TextureResource(
            image: gridTexture,
            withName: "grayGridTexture",
            options: TextureResource.CreateOptions(semantic: .color)
        ) else {
            fatalError("Failed to create texture resource")
        }
        
        var gridMaterial = UnlitMaterial()
        gridMaterial.color = .init(texture: .init(textureResource))
        gridMaterial.blending = .transparent(opacity: 0.8)
        gridMaterial.faceCulling = .none
        
  
        let mesh = MeshResource.generatePlane(width: size, depth: size)
        let floor = ModelEntity(mesh: mesh, materials: [gridMaterial])
        floor.name = "GridFloor"
        
        return floor
    }
}
