//
//  SignUpViewController.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-09.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import UIKit
 import Firebase
 import GoogleSignIn
import FirebaseAuth

//User Registration Screen
class SignUpViewController: UIViewController,GIDSignInUIDelegate
{

    @IBOutlet weak var labelOR: UILabel!
    @IBOutlet weak var btnGuest: UIButton!
    @IBOutlet weak var btnstartGame: UIButton!
    @IBOutlet weak var labelWelcome: UILabel!
    @IBOutlet weak var btnLogout: UIButton!
      var googleButton : GIDSignInButton!;
    @IBAction func onLogoutClicked(_ sender: Any) {
                do{
                try Auth.auth().signOut()
                } catch let error {
                    print("Error: \(error)")
                }
                    //Show Google Button Back
                googleButton.isHidden = false
                //Hide Logout Button
                btnLogout.isHidden = true
                //Hide Welcome Text
                labelWelcome.isHidden = true
                //Show OR text
                labelOR.isHidden = false
                //Show Guest Button
                btnGuest.isHidden = false
                //Hide Start Game Button
                btnstartGame.isHidden = true
    }
    
    override func viewDidLoad() {
        
    super.viewDidLoad()
    self.view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_main.png")!)
    googleButton = GIDSignInButton()
    googleButton.frame = CGRect(x:(view.frame.width/2)-30, y:496+16,  width: 100,height: 50)
    view.addSubview(googleButton)
    GIDSignIn.sharedInstance()?.uiDelegate = self
        
        var handle = Auth.auth().addStateDidChangeListener { (auth, user) in
          // ...
            if let name = Auth.auth().currentUser?.displayName {
               print("Welcome, \(name)")
            
            self.btnLogout.isHidden = false
            //Hide the google button
           self.googleButton.isHidden = true
            //Show Welcome Text
            self.labelWelcome.text = "Welcome, \(name)"
            self.labelWelcome.isHidden = false
            //Show Logout Button on top left
           self.btnLogout.isHidden = false
            //Show Start Game Button
           self.btnstartGame.isHidden = false
            //Hide Guest Button
           self.btnGuest.isHidden = true
            //Hide the OR text
           self.labelOR.isHidden = true
        }
        if Auth.auth().currentUser != nil {
                   if let name = Auth.auth().currentUser?.displayName {
                       print("Welcome, \(name)")
                    
                   self.btnLogout.isHidden = false
                    //Hide the google button
                  self.googleButton.isHidden = true
                    //Show Welcome Text
                  self.labelWelcome.text = "Welcome, \(name)"
                  self.labelWelcome.isHidden = false
                    //Show Logout Button on top left
                  self.btnLogout.isHidden = false
                    //Show Start Game Button
                  self.btnstartGame.isHidden = false
                    //Hide Guest Button
                 self.btnGuest.isHidden = true
                    //Hide the OR text
                 self.labelOR.isHidden = true
                       }
                   }
        


//    @IBAction func onLogoutClicked(_ sender: Any) {
//

//
//    }
    
  
}
}
}
