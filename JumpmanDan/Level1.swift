//
//  Level1.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 5/25/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class Level1: LevelScene {
    
    override var LEVEL_NAME: String {
        return Level.One.name()
    }
    
    override var LEVEL_SPEED: CGFloat {
        return 3.0
    }
    
}
