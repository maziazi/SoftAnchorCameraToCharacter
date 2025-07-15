//
//  CanvasView.swift
//  Canvas3DDragDrop
//
//  Created by Muhamad Azis on 23/06/25.
//

import SwiftUI
import RealityKit

struct CanvasView: View {
    @State private var placedObjects: [Entity] = []
    @State private var showingExportSheet = false
    @State private var moveTimer: Timer?
    @State private var cameraMode: String = "Overview"
    
    // HARDCODED CAMERA PARAMETERS
    private let moveSpeed: Float = 0.01
    private let moveInterval: TimeInterval = 0.016
    
    // HARDCODED FOLLOW PARAMETERS
    private let followEnabled: Bool = true
    private let followSmoothness: Float = 0.08
    private let followOffset: SIMD3<Float> = SIMD3<Float>(0, 8, 0)
    
    var body: some View {
        ZStack {
            RealityKitCanvasView(placedObjects: $placedObjects)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    loadKursiToCenter()
                }
                .onDisappear {
                    stopIdleMovement()
                }
            
            // Camera Mode Indicator - Minimal UI
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Camera Mode")
                            .font(.caption)
                            .foregroundColor(.white)
                            .opacity(0.8)
                        Text(cameraMode)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        
                        // ✨ NEW: Show side movement instructions in follow mode
                        if cameraMode == "Follow" {
                            Text("Swipe left/right to steer")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .opacity(0.7)
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateCameraMode()
        }
    }
    
    func loadKursiToCenter() {
        Task {
            do {
                var kursiURL: URL?
                
                if kursiURL == nil {
                    kursiURL = Bundle.main.url(forResource: "Kursi", withExtension: "usdz")
                }
                
                guard let finalKursiURL = kursiURL else {
                    print("Kursi USDZ file not found! Tried multiple paths:")
                    return
                }
                
                print("Found kursi file at: \(finalKursiURL.path)")
                let kursiModel = try await ModelEntity(contentsOf: finalKursiURL)
                
                await MainActor.run {
                    kursiModel.name = "kursi"
                    kursiModel.generateCollisionShapes(recursive: true)
                    kursiModel.position = SIMD3<Float>(0, 0, 0)
                    kursiModel.scale = SIMD3<Float>(1.0, 1.0, 1.0)
                
                    placedObjects.append(kursiModel)
                    print("Kursi loaded successfully from: \(finalKursiURL.lastPathComponent)")
                    
                    // Setup camera dengan hardcoded parameters
                    setupHardcodedCameraFollow(target: kursiModel)
                    
                    startIdleMovement()
                }
            } catch {
                print("Failed to load kursi.usdz: \(error)")
            }
        }
    }
    
    // 🎯 SETUP CAMERA DENGAN HARDCODED PARAMETERS
    func setupHardcodedCameraFollow(target: Entity) {
        // Set kursi sebagai follow target
        UnifiedCameraManager.setFollowTarget(target)
        
        // Apply hardcoded parameters
        UnifiedCameraManager.setFollowSmoothness(followSmoothness)
        UnifiedCameraManager.setFollowOffset(followOffset)
        
        if followEnabled {
            UnifiedCameraManager.enableFollow()
        } else {
            UnifiedCameraManager.disableFollow()
        }
        
        print("🎯 Camera follow configured with HARDCODED parameters:")
        print("   - Smoothness: \(followSmoothness)")
        print("   - Offset: X=\(followOffset.x), Y=\(followOffset.y), Z=\(followOffset.z)")
        print("   - Enabled: \(followEnabled)")
        print("   - Target: \(target.name)")
        
        // Auto switch to follow mode setelah 1 detik
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.switchToFollowMode()
        }
    }
    
    func startIdleMovement() {
        moveTimer = Timer.scheduledTimer(withTimeInterval: moveInterval, repeats: true) { _ in
            moveChairForward() // ✨ UPDATED: Renamed for clarity
        }
    }
    
    func stopIdleMovement() {
        moveTimer?.invalidate()
        moveTimer = nil
    }
    
    // ✨ UPDATED: Enhanced forward movement (unchanged behavior but clearer naming)
    func moveChairForward() {
        guard let kursi = placedObjects.first(where: { $0.name == "kursi" }) else {
            return
        }
        
        // Continue forward movement as before
        kursi.position.z -= moveSpeed
        
        // Reset position when chair goes too far back
        if kursi.position.z < -5.0 {
            kursi.position.z = 2.0
            // ✨ NEW: Reset X position to center when resetting Z (optional)
            // Uncomment next line if you want chair to return to center X when resetting
            // kursi.position.x = 0
        }
    }
    
    func switchToFollowMode() {
        if let coordinator = getCurrentCoordinator() {
            coordinator.setCameraToFollowMode()
        }
    }
    
    func switchToOverviewMode() {
        if let coordinator = getCurrentCoordinator() {
            coordinator.setCameraToOverviewMode()
        }
    }
    
    func updateCameraMode() {
        cameraMode = UnifiedCameraManager.getCurrentModeString()
    }
    
    // Helper function untuk mendapatkan coordinator
    private func getCurrentCoordinator() -> CanvasCoordinator? {
        return nil
    }
}
