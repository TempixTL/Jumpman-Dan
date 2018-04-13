//
//  Level2.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 5/30/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class Level2: LevelScene {
    
    override var LEVEL_SPEED: CGFloat {
        get {
            return 4.5
        }
    }
    
    override var LEVEL_NAME: String {
        get {
            return Level.Two.name()
        }
    }
    
}
