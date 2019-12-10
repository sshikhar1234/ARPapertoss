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


enum RConfigurationProgress {
    case preparing
    case detectingPlanes
    case placingObjects
    case completed
}


class SecondViewController: UIViewController,SCNPhysicsContactDelegate,ARSessionDelegate,ARSCNViewDelegate{
    @IBOutlet weak var labelLocalBestScore: UILabel!
    @IBOutlet weak var labelGlobalHighscore: UILabel!
    @IBOutlet weak var labelCurrentScore: UILabel!
    
    
    @IBOutlet var sceneView: ARSCNView!
    let sceneManager = ARSceneManger()

    private var paperNode: SCNNode?
    private var panSurfaceNode: SCNNode?
    private var planeNodes = [ARPlaneAnchor: PlaneNode]()
    private var trashcanNode: SCNNode?
    private var score: Int = 0
//    private var highscore: Int = 0
    private var fetchedHighscore: Int = 0
    let scene = SCNScene()

    //Tracks the configuration
    var configurationProgress: RConfigurationProgress?
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        sceneManager.attach(to: sceneView)
//        sceneView.scene.physicsWorld.contactDelegate = self
//        sceneManager.displayDegubInfo()
        setupGestureRecognizers()
        setupScoreStats()
        self.labelCurrentScore.text = "Start Game!"
    }

    
    func setUpSceneView() {
          let configuration = ARWorldTrackingConfiguration()
          configuration.planeDetection = .horizontal
          
          sceneView.session.run(configuration)
          
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneManager.displayDegubInfo()
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
      }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpSceneView()
    }
    
    
    
    
   func setupScoreStats(){
    //Current
    print("score: \(score)")
    self.labelCurrentScore.text = "Current: \(score)"
    //Highscore
    fetchedHighscore = getScoreFromLocalDb()
    if(fetchedHighscore>0){
        self.labelLocalBestScore.text = "Your BEST: \(fetchedHighscore)"
    }
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

    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }


    //Done
    private func setupGestureRecognizers() {

       // Add tap gesture recognizer
       let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture))
       sceneView.addGestureRecognizer(tapGestureRecognizer)

       // Add pan gesture recognizer
       let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture))
       sceneView.addGestureRecognizer(panGestureRecognizer)

    // Add pan surface
           let panSurfaceNode = createPanSurfaceNode()
           panSurfaceNode.isHidden = true
           panSurfaceNode.position = SCNVector3(0, 0, -0.2)

        if let pointOfView = sceneView.pointOfView {
               pointOfView.addChildNode(panSurfaceNode)
               self.panSurfaceNode = panSurfaceNode
           }
       }

    private func createPanSurfaceNode() -> SCNNode {
           // Create plane geometry
           let geometry = SCNPlane()
           
           // Create and return the node
           let node = SCNNode(geometry: geometry)
           return node
       }

    
    
    //Working, not finished
    @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
          //Called when the user taps on screen
        print("Tap received")
        //Put the trash can
//        guard configurationProgress == .placingObjects else {
//            print("Guard 0 Error")
//return }
              
              // Get the world position of the recognizer
              guard let position = getPositionInWorld(from: sender) else {
                  print("Guard 1 Error")
                  return
              }
              
              // Add trashcan node to the selected position.
              trashcanNode?.removeFromParentNode()
              guard let trashcanNode = SCNScene(named: "art.scnassets/trashcan.scn")?.rootNode else {
                print("Guard 2 Error")
                  return
              }
              trashcanNode.position = position
              sceneView.scene.rootNode.addChildNode(trashcanNode)
              self.trashcanNode = trashcanNode
        
        enterCompletedPhase()
      }

    //Working, not finished
   @objc func didReceivePanGesture(_ sender: UIPanGestureRecognizer) {
           
           guard configurationProgress == .completed else { return }
           
           // Handle .ended
           guard sender.state != .ended else {
               
               paperNode?.physicsBody?.isAffectedByGravity = true
               
               // Apply outward force to the paper ball
               let (userDirection, _) = getUserVectors()
               let velocity = sender.velocity(in: sceneView)
               let norm = Float(sqrt(pow(velocity.x, 2) + pow(velocity.y, 2))) / 1000
               let outwardForce = SCNVector3(userDirection.x * norm, userDirection.y * norm, userDirection.z * norm)
               paperNode?.physicsBody?.applyForce(outwardForce, asImpulse: true)
               
               // Apply upward force to the paper ball
               let upwardForce = SCNVector3(0, norm, 0)
               paperNode?.physicsBody?.applyForce(upwardForce, asImpulse: true)
               return
           }
           
           // Handle .failed, .cancelled
           let allowedStates: [UIGestureRecognizer.State] = [.began, .changed]
           guard allowedStates.contains(sender.state) else {
               paperNode?.removeFromParentNode()
               paperNode = nil
               return
           }
           
           // Handle .began
           if sender.state == .began {
               
               // Reset score if last ball didn't hit
               if let previousNode = self.paperNode {
                   print("Missed")
                   score = 0
                   let fadeOutAction = SCNAction.fadeOut(duration: 1)
                   previousNode.runAction(fadeOutAction, completionHandler: {
                       previousNode.removeFromParentNode()
                   })
               }
               
               
               // Create new paper node
               let paperNode = createPaperNode()
               sceneView.scene.rootNode.addChildNode(paperNode)
               self.paperNode = paperNode
           }
           
           // Update paper node position
           let touchLocation = sender.location(in: sceneView)
           let hitTestResult = sceneView.hitTest(touchLocation, options: [.ignoreHiddenNodes: false, .searchMode: SCNHitTestSearchMode.all.rawValue])
           for result in hitTestResult {
               if result.node === panSurfaceNode {
                   paperNode?.position = result.worldCoordinates
               }
           }
       }
    private func createPaperNode() -> SCNNode {
        
        // Create paper material
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.lightingModel = .physicallyBased
        
        // Create paper geometry
        let geometry = SCNSphere(radius: 0.05)
        geometry.isGeodesic = true
        geometry.segmentCount = 10
        geometry.materials = [material]
        
        // Create physics body
        let physicsShape = SCNPhysicsShape(geometry: geometry, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        physicsBody.categoryBitMask = CategoryBitMask.paper
        physicsBody.collisionBitMask = CategoryBitMask.all
        physicsBody.contactTestBitMask = CategoryBitMask.target
        
        // Create and return the node
        let node = SCNNode(geometry: geometry)
        node.physicsBody = physicsBody
        return node
    }
    
    private func getPositionInWorld(from recognizer: UIGestureRecognizer) -> SCNVector3? {
           
           // Hit test the tap gesture location in the scene view.
           guard let sceneView = recognizer.view as? ARSCNView else {
               return nil
           }
           let tapLocation = recognizer.location(in: sceneView)
        print("getPositionInWorld")
        print(tapLocation)
           let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlane)
           
           // Check if the hit test resulted in at least one hit.
           guard let firstResult = hitTestResults.first else {
               return nil
           }
           
           return firstResult.positionInWorld
       }
  private func enterPlaneDetectionPhase() {

        configurationProgress = .detectingPlanes
        // Show feature points
          sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

          // Create a plane detecting session configuration

    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        print("renderer: didAdd")
        // Check if the anchor represents a plane
        guard let planeAnchor = anchor as? ARPlaneAnchor else
        {
            print("Guard 1")
            return
        }
        // Update the plane node with the anchor
        if let plane = planeNodes[planeAnchor] {
            plane.update(anchor: planeAnchor)
        }
        // Create a plane node for the anchor
        let plane = PlaneNode(anchor: planeAnchor)
        planeNodes[planeAnchor] = plane
        node.addChildNode(plane)

        

        // Update the configuration progress if detecting planes.
        if configurationProgress == .detectingPlanes {

            DispatchQueue.main.async {
                // Vibrate to let the user know plane detection is done.
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

                self.enterObjectPlacementPhase()
            }
        }
    }
    private func enterObjectPlacementPhase() {
          
          configurationProgress = .placingObjects
          // Show detected planes
          showPlaneNodes()
      }
    private func showPlaneNodes() {
           SCNTransaction.animationDuration = 1
           for (_, node) in planeNodes {
               node.opacity = 1
           
        }
       }
    
    
    private func getUserVectors() -> (direction: SCNVector3, position: SCNVector3) {
           
           if let frame = self.sceneView.session.currentFrame {
               
               let mat = SCNMatrix4(frame.camera.transform)                    // 4x4 transform matrix describing camera in world space
               let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)  // orientation of camera in world space
               let pos = SCNVector3(mat.m41, mat.m42, mat.m43)                 // location of camera in world space
               
               return (dir, pos)
           }
           
           return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
       }
    private func enterCompletedPhase() {
          print("enterCompletedPhase")
          configurationProgress = .completed
        // Don't show feature points
        sceneView.debugOptions = []
          // Hide detected planes
          hidePlaneNodes()
      }
    private func hidePlaneNodes() {
        SCNTransaction.animationDuration = 1
//        for (_, node) in planeNodes {
//            print("FOR LOOP")
//            node.opacity = 0
//        }
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        guard let aBody = contact.nodeA.physicsBody, let bBody = contact.nodeB.physicsBody else {
            print("aBody | bBody")

            return
        }
        
        let contactMask = aBody.categoryBitMask | bBody.categoryBitMask
        let goalMask = CategoryBitMask.paper | CategoryBitMask.target
        
        if contactMask == goalMask {
            let nodes = [contact.nodeA, contact.nodeB]
            if let paper = (nodes.filter { $0.name != "target" }).first {
                
                print("paper")
                // Disable further interaction and remove
                paper.physicsBody = nil
                paper.removeFromParentNode()
                paperNode = nil
                
                // Show score overlay
                score += 1
                
                if(score > fetchedHighscore){
                    fetchedHighscore = score
                    DispatchQueue.main.async {
                            self.labelLocalBestScore.text = "Highscore: \(self.fetchedHighscore)"
                            self.saveScoretoLocalDb(score: self.fetchedHighscore)
                        
                    }

                }
                print("Scores: ")
                print("HighScore \(self.fetchedHighscore)")
                print("Current \(self.score)")
                DispatchQueue.main.async {
                    self.labelCurrentScore.text = "Current: \(self.score)"
                    
                }
                updateScoreNode(score: score)
            }
        }
    }
    private var scoreNode: SCNNode?
       
       func updateScoreNode(score: Int) {
           print("updateScoreNode")
           let textMaterial = SCNMaterial()
           textMaterial.diffuse.contents = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
           
        print("Score: ")
        print(score)
           // Create text geometry
           let text = SCNText(string: "Score: \(score)", extrusionDepth: 0.01)
           text.materials = [textMaterial]
           text.font = UIFont.systemFont(ofSize: 0.1)
           text.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        
           
           
           // Create and center text node
           let textNode = SCNNode(geometry: text)
           centerPivot(for: textNode)
           textNode.position.y = 0.5
           
           // Constrain to always look at camera
           let lookAtCameraConstraint = SCNBillboardConstraint()
           lookAtCameraConstraint.freeAxes = [.Y, .X]
           textNode.constraints = [lookAtCameraConstraint]
           
           // Add to scene by replacing old node
           scoreNode?.removeAllActions()
           scoreNode?.removeFromParentNode()
           scoreNode = textNode
           trashcanNode?.addChildNode(textNode)
           textNode.runAction(SCNAction.fadeOut(duration: 2))
       }
       
       func centerPivot(for node: SCNNode) {
           let (min, max) = node.boundingBox
           node.pivot = SCNMatrix4MakeTranslation(
               min.x + (max.x - min.x)/2,
               min.y + (max.y - min.y)/2,
               min.z + (max.z - min.z)/2
           )
       }

    func saveScoretoLocalDb(score: Int){
        UserDefaults.standard.set(score, forKey: "highscore")
        print("Data Saved")
    }
    func getScoreFromLocalDb()->NSInteger{
         var fetchedScore: NSInteger  = UserDefaults.standard.integer(forKey: "highscore")
        
        if(fetchedScore != nil){
            print("Score fetched from local storage : ")
                   print(fetchedScore)
//            DispatchQueue.main.async {
//                self.labelLocalBestScore.text = "Your highscore: \(fetchedScore)"
//            }
            return fetchedScore
        }
        else{
            return 0
        }
    }
}
