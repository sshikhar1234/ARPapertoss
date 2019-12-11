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
import FirebaseDatabase
import FirebaseAuth


enum RConfigurationProgress {
    case preparing
    case detectingPlanes
    case placingObjects
    case completed
}


class SecondViewController: UIViewController,SCNPhysicsContactDelegate,ARSessionDelegate,ARSCNViewDelegate{
    
    
    @IBOutlet weak var labelLocalBestScore: UILabel!
    @IBOutlet weak var labelLives: UILabel!
    @IBOutlet weak var labelCurrentScore: UILabel!
    
    private var firebaseData : [String] = []
    private var gamePlaying = false
    private var planeDetected = false

    private var powerupRemaining = 2
    @IBOutlet var sceneView: ARSCNView!
    let sceneManager = ARSceneManger()
    
    private var paperNode: SCNNode?
    private var powerUpNode: SCNNode?

    private var panSurfaceNode: SCNNode?
    private var planeNodes = [ARPlaneAnchor: PlaneNode]()
    private var trashcanNode: SCNNode?
    private var score: Int = 0
    private var lives = 3
    private var fetchedHighscore: Int = 0
    let scene = SCNScene()
     let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture))

    private let STRING_FIREBASE_DB_REF = "https://paperartoss.firebaseio.com/"
    //Tracks the configuration
    var configurationProgress: RConfigurationProgress?
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad")

        gamePlaying = true
        
    }

    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           print("ViewWillAppear")
           setUpSceneView()
           setupGestureRecognizers()
           setupScoreStats()
       }
    
    //SETUP FUNCTION sets up the scene view
    func setUpSceneView() {
          let configuration = ARWorldTrackingConfiguration()
          configuration.planeDetection = .horizontal
          sceneView.session.run(configuration)
          
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneManager.displayDegubInfo()
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
       
      }
    
    //SETUP FUCTION sets up the UI with local highscore
   func setupScoreStats(){
    //Current
    print("score: \(score)")
    self.labelCurrentScore.text = "Current: \(score)"
    //Highscore
    fetchedHighscore = getScoreFromLocalDb()
    if(fetchedHighscore>0){
        self.labelLocalBestScore.text = "Your BEST: \(fetchedHighscore)"
    }
    self.labelLives.text = "Lives: \(self.lives)"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    //PHASE CHANGE FUNCTION sets the status to PREPARING
    private func enterPreparationPhase() {

          configurationProgress = .preparing

              sceneView.debugOptions = []

              // Create a world tracking session configuration
              let configuration = AROrientationTrackingConfiguration()

              // Run the view's session
              sceneView.session.run(configuration)

    }

    //PHASE CHANGE FUNCTION configures the app to detect Planes
    private func enterPlaneDetectionPhase() {

          configurationProgress = .detectingPlanes
          // Show feature points
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

            // Create a plane detecting session configuration

      }
    
    //PHASE CHANGE FUNCTION configures the app to place Objects
    private func enterObjectPlacementPhase() {
          configurationProgress = .placingObjects
          // Show detected planes
          //showPlaneNodes()
      }
    
    ///MENDATORY OVERRIDE
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user

    }
    ///MENDATORY OVERRIDE
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    ///MENDATORY OVERRIDE
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }
     ////MENDATORY OVERRIDE
     func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

     }
    
     ///MENDATORY OVERRIDE called when a plane is added in Sceneview
     func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

         if(gamePlaying)
         {
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
                   if(planeDetected==false)  {
                       node.addChildNode(plane)
                     planeDetected = true
                     self.enterObjectPlacementPhase()
                   }
             else  {
             DispatchQueue.main.async {
                 self.sceneView.removeGestureRecognizer(self.tapGestureRecognizer)
                 
                     }
             }
         }
         
     }
     

    //CALLBACK called when a collision occurs in the augmented world
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {

        guard let aBody = contact.nodeA.physicsBody, let bBody = contact.nodeB.physicsBody else {
            return
        }
    
        let contactMask = aBody.categoryBitMask | bBody.categoryBitMask
        let goalMask = CategoryBitMask.paper | CategoryBitMask.target
        let goalMaskTwo = CategoryBitMask.paper |  CategoryBitMask.powerup
               
//        print("Contact \(contactMask)")
//        print("Goal \(goalMask)")

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
                
                //Randomly choose lower bound
                let lowerboundOne = Int.random(in: 5 ..< 7)
                
                //Generate a number between that lowerbound and 25
                let lowerboundTwo = Int.random(in: 13 ..< 17)
                
                //If the score is between 0 and uppoerbound, spawn a powerup ball
                
                
                //TIME FOR FIRST POWERUP
                if(score>lowerboundOne && score<10 && self.powerupRemaining>2){
                    print("generatePowerup")
                                   let powerUp = createPowerups()
                                   sceneView.scene.rootNode.addChildNode(powerUp)
                                   self.powerUpNode = powerUp
                    self.powerupRemaining = self.powerupRemaining - 1
                               }
                
                //TIME FOR SECOND POWERUP

                if(score>10 && score<20 && self.powerupRemaining>1){
                                   print("generatePowerup")
                                                  let powerUp = createPowerups()
                                                  sceneView.scene.rootNode.addChildNode(powerUp)
                                                  self.powerUpNode = powerUp
                    self.powerupRemaining = self.powerupRemaining - 1

                                              }
                
                
                if(score > fetchedHighscore){
                    fetchedHighscore = score
                    DispatchQueue.main.async {
                            self.labelLocalBestScore.text = "Highscore: \(self.fetchedHighscore)"
                            self.saveScoretoLocalDb(score: self.fetchedHighscore)
                        print("Dispatch")
                            self.fetchLastSubmittedHighscore()
                    }

                }
              
                DispatchQueue.main.async {
                    self.labelCurrentScore.text = "Current: \(self.score)"
                }
               
            }
            
        }
         
         if(contactMask == goalMaskTwo){
             //Collision with powerup
            powerUpNode?.physicsBody?.categoryBitMask = 0

             print("Powered up!")
             
            
            DispatchQueue.main.async {
                               //Update the UI
                self.lives = self.lives + 2
                               self.labelLives.text = "Lives: \(self.lives)"
                               let fadeOutAction = SCNAction.fadeOut(duration: 1)
                self.powerUpNode!.runAction(fadeOutAction, completionHandler: {
                    self.powerUpNode!.removeFromParentNode()
                               })
                                       }
            
         }
        
    }
                   
    //CALLBACK received when user taps on screen
    @objc func didReceiveTapGesture(_ sender: UITapGestureRecognizer) {
          //Called when the user taps on screen
        print("Tap received")
        if(gamePlaying)
        {
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
              
      }

    //CALLBACK received when user swipes on screen
   @objc func didReceivePanGesture(_ sender: UIPanGestureRecognizer) {
    
    if(gamePlaying)
          {
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

                //Decrement life by 1
                lives = lives - 1
                 DispatchQueue.main.async {
                    //Update the UI
                    self.labelLives.text = "Lives: \(self.lives)"
                    let fadeOutAction = SCNAction.fadeOut(duration: 1)
                    previousNode.runAction(fadeOutAction, completionHandler: {
                        previousNode.removeFromParentNode()
                    })
                            }
                if(lives == 0)
                {
                    score = 0
                    
                    
                    //Stop the game
                    gamePlaying = false
                    //Remove All the nodes
                    self.labelCurrentScore.text = "Score: \(self.score)"
                    self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                    node.removeFromParentNode()
                    }
                    //Remove both tap and pan gestures
                    for recognizer in sceneView.gestureRecognizers ?? [] {
                    sceneView.removeGestureRecognizer(recognizer)
                       }
                    //Prompt Game Over dialog
                    showGameOverDialog()
                    //Remove the current papernode
                    paperNode?.removeFromParentNode()
                    
                }
                   print("Missed")
                
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
       }
    
   
    //FUNCTION sets up GestureRecognizers on SceneView
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

      //FUNCTION creates a SCNPlane for display
      private func createPanSurfaceNode() -> SCNNode {
             // Create plane geometry
             let geometry = SCNPlane()
             
             // Create and return the node
             let node = SCNNode(geometry: geometry)
             return node
         }

    //FUNCTION creates the powerup cubes
    private func createPowerups() -> SCNNode {
            
                  // Create paper material
                  let material = SCNMaterial()
//                  material.diffuse.contents = UIColor.red

        material.diffuse.contents = UIImage(named: "powerup.jpeg")
        material.lightingModel = .physicallyBased

                  // Create paper geometry
        let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
//                  geometry.isGeodesic = true
//                  geometry.segmentCount = 10
                  geometry.materials = [material]
                  
                  // Create physics body
                  let physicsShape = SCNPhysicsShape(geometry: geometry, options: nil)
                  let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
                  physicsBody.isAffectedByGravity = false
                  physicsBody.categoryBitMask = CategoryBitMask.powerup
                  physicsBody.collisionBitMask = CategoryBitMask.all
                  physicsBody.contactTestBitMask = CategoryBitMask.all
                  
                  // Create and return the node
                  let node = SCNNode(geometry: geometry)
            let position = SCNVector3Make(0, 0, 0)

                    node.position = position
                  node.physicsBody = physicsBody
                  return node
              }

     //FUNCTION creates paperballs
    private func createPaperNode() -> SCNNode {
           
           // Create paper material
           let material = SCNMaterial()
           material.diffuse.contents = UIColor.white
           material.lightingModel = .physicallyBased
           
           // Create paper geometry
           let geometry = SCNSphere(radius: 0.05)
           geometry.isGeodesic = true
           geometry.segmentCount = 5
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
    
     //FUNCTION gets tap or pan point's location
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
    
    //FUNCTION that shows detected planes
    private func showPlaneNodes() {
           SCNTransaction.animationDuration = 1
           for (_, node) in planeNodes {
               node.opacity = 1
           
        }
       }
   
    //FUNCTION that hides detected planes
    private func hidePlaneNodes() {
          SCNTransaction.animationDuration = 1
          for (_, node) in planeNodes {
             
              node.opacity = 0
          }
      }
    
    //FUNCTION calculates user's pan directiona and 4x4 matrix of person's tapped location
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
    
    //DB FUNCTION that saves user's code locally
    func saveScoretoLocalDb(score: Int){
        UserDefaults.standard.set(score, forKey: "highscore")
        print("Data Saved")
    }
    
    //DB FUNCTION that fetches user's code locally
    func getScoreFromLocalDb()->NSInteger{
        let fetchedScore: NSInteger  = UserDefaults.standard.integer(forKey: "highscore")
        
        if(fetchedScore != nil){
            print("Score fetched from local storage : ")
                   print(fetchedScore)
            return fetchedScore
        }
        else{
            return 0
        }
    }
    
    
    //DB FUNCTION that saves user's code on Firebase Cloud
    func saveScoretoGlobalDb(score: Int){
        print("Attempting to save score on cloud")
        let reference = Database.database().reference(fromURL: STRING_FIREBASE_DB_REF)
        let email:String = Auth.auth().currentUser?.email as! String
        var username: String  = email.substring(to: (email.lastIndex(of: "@"))!)
        
        var userProfile: UserProfile = UserProfile.init(username: username, highscore: score, email: email)
        let dictionaryNode = ["email": email,"username":username,"highscore":score] as [String : Any]

        reference.updateChildValues([username:dictionaryNode],withCompletionBlock: {(error,ref) in
            if error != nil{
                print(error)
                return
            }
            print("Highscore submitted to global leaderboard")
        })
       }
    
    
    //DB FUNCTION that fetches user's last highscore from cloud
    func fetchLastSubmittedHighscore(){
    print("fetchLastSubmittedHighscore")
    let ref = Database.database().reference()
//        let email = getUserLocalDb();
    var username = getUserLocalDb()
    
    if(username == "nil")
    {
        self.saveScoretoLocalDb(score: score)
        self.saveScoretoGlobalDb(score: self.self.fetchedHighscore)
        
    }else{
        
        ref.observe(.childAdded, with: { (snapshot) in
                print("DICT \(snapshot)")
            if let dictionary = snapshot.value as? NSDictionary {
                
                if(snapshot.key == (username))
                {
                    print("Snapshot.key == username")
                for (key, value) in dictionary {

                    if(key as! String == "highscore")
                    {
                        let dbHighScore: Int = value as! Int
                        
                        print("DB HIGHSCORE: \(dbHighScore)")
                        if(dbHighScore<self.fetchedHighscore)
                        {
                            //Only update the highscore on cloud if local highscore is greater than cloud one's
                            
                            self.saveScoretoGlobalDb(score: self.self.fetchedHighscore)
                        }
                        print("Got score \(dbHighScore)")
                    }
                    }
                    }
                else
                {
                    print("Snapshot.key != username")
                    self.saveScoretoGlobalDb(score: self.self.fetchedHighscore)
                }
                
                print(snapshot.value!)

                    }
        })
    }

    }
       
    //DB FUNCTION that fetches logged in user from Local Storage
      func getUserLocalDb()->String{
      
      let fetchedUser: String  = NSString( string: UserDefaults.standard.string(forKey: "currentuser")!) as String
                 
                 if(fetchedUser != nil){
                     print("User fetched from local storage : \(fetchedUser)")
                           
                     return fetchedUser
                 }
                 else{
                     return "nil"
                 }
       
      }
    
        
    // ONCLICK FUNCTION Close the game session
    @IBAction func onCloseClicked(_ sender: Any) {
        navigationController?.popViewController(animated: true)

        dismiss(animated: true, completion: nil)
    }
    
   //FUNCTION that shows Game Over Screen
    func showGameOverDialog(){
        let alert = UIAlertController(title: "Game Over!", message: "Oops! Looks like you're out of lives!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
              switch action.style{
              case .default:
                
                self.navigationController?.popViewController(animated: true)

                self.dismiss(animated: true, completion: nil)
              case .cancel:
                    print("cancel")

              case .destructive:
                    print("destructive")


        }}))
        self.present(alert, animated: true, completion: nil)
    }
    
   
}
