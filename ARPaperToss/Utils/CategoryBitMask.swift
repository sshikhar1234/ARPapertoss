//
//  AppDelegate.swift
//  ARPaperToss
//
//  Created by Shikhar Shah on 2019-12-09.
//  Copyright © 2019 Lambton. All rights reserved.
//

import Foundation

struct CategoryBitMask {
    static let all      =   0b11111111
    static let floor    =   0b00000001
    static let wall     =   0b00000010
    static let paper    =   0b00000100
    static let target   =   0b00001000
    static let powerup   =  0b00010000
}
