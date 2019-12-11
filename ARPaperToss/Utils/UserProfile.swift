//
//  UserProfile.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-10.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
class UserProfile {
       var username: String
       var highScore: Int
       var email: String
       
       init(username: String,
            highscore: Int,
            email: String) {
           self.username = username
           self.highScore = highscore
           self.email = email
       }
   }
