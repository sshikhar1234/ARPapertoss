//
//  ViewController.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-09.
//  Copyright © 2019 Lambton. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


enum ARConfigurationProgress {
    case preparing
    case detectingPlanes
    case placingObjects
    case completed
}


class MainScreenViewController: UIViewController, ARSCNViewDelegate,SCNPhysicsContactDelegate{

    @IBOutlet var sceneView: ARSCNView!

    //Tracks the configuration
    var configurationProgress: ARConfigurationProgress?
   
    
    private var panSurfaceNode: SCNNode?

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSceneView()
        setupGestureRecognizers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)

           enterPreparationPhase()
           
           // Disallow sleeping while in ar
           UIApplication.shared.isIdleTimerDisabled = true
       }
      private func setupSceneView() {
           sceneView.delegate = self
           let scene = SCNScene(named: "art.scnassets/world.scn")!
           sceneView.scene = scene
           sceneView.scene.physicsWorld.contactDelegate = self
       }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    private func enterPreparationPhase() {
          
          configurationProgress = .preparing
          
              sceneView.debugOptions = []
              
              // Create a world tracking session configuration
              let configuration = AROrientationTrackingConfiguration()
              
              // Run the view's session
              sceneView.session.run(configuration)
              
        
//          // Present helper view controller
//          guard let helperViewController = helperViewController else {
//              return
//          }
//          helperViewController.configurationBlock = { controller in
//              controller.configureForSceneSelection()
//          }
//          helperViewController.completionBlock = {
//              self.enterPlaneDetectionPhase()
//              self.activeHelperViewController = nil
//          }
//          present(helperViewController, animated: true) {
//              self.activeHelperViewController = helperViewController
//          }
      }
    
    
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    private func setupGestureRecognizers() {
           
           // Add tap gesture recognizer
           let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture))
           sceneView.addGestureRecognizer(tapGestureRecognizer)
           
           // Add pan gesture recognizer
           let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture))
           sceneView.addGestureRecognizer(panGestureRecognizer)
           
        // Create plane geometry
        let geometry = SCNPlane()
                
        // Create and return the node
        let panSurfaceNode = SCNNode(geometry: geometry)
        
           panSurfaceNode.isHidden = true
           panSurfaceNode.position = SCNVector3(0, 0, -0.2)
           if let pointOfView = sceneView.pointOfView {
               pointOfView.addChildNode(panSurfaceNode)
               self.panSurfaceNode = panSurfaceNode
           }
       }
    
    @objc private func didReceiveTapGesture(){
          //Called when the user taps on screen
        print("Tap received")
      }
    
    @objc private func didReceivePanGesture(){
          //Called when the user swipes the paper ball
          print("Pan received")
      }
    
  
}
