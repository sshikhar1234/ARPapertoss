//
//  AppDelegate.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-09.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation
import ARKit

extension ARHitTestResult {
    
    var positionInWorld: SCNVector3 {
        
        // Calculate the position of the tap in 3D space.
        let x = worldTransform.columns.3.x
        let y = worldTransform.columns.3.y
        let z = worldTransform.columns.3.z
        
        return SCNVector3Make(x, y, z)
    }
}
