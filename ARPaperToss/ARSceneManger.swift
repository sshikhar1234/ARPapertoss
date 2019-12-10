//
//  ARSceneManger.swift
//  PlaneDetection
//
//  Created by Shikhar Shah on 2019-12-04.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import ARKit
class ARSceneManger: NSObject {
    var sceneView: ARSCNView?

    func attach(to sceneView: ARSCNView) {
        self.sceneView = sceneView

        self.sceneView!.delegate = self as? ARSCNViewDelegate
        configureSceneView(self.sceneView!)
    }
    private func configureSceneView(_ sceneView: ARSCNView) {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            configuration.isLightEstimationEnabled = true
            configuration.environmentTexturing = .automatic

            sceneView.session.run(configuration)
        
    }
    // 3
    func displayDegubInfo() {
        sceneView?.showsStatistics = true
        sceneView?.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
    }

}
extension ARSceneManger: ARSCNViewDelegate {

func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    // we only care about planes
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
    print("Found plane: \(planeAnchor)")
}
}
