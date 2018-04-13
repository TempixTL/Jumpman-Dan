//
//  LevelTest.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/21/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class LevelTest: LevelScene {
    
    override var LEVEL_SPEED: CGFloat {
        return 4
    }
    
    override var LEVEL_NAME: String {
        return Level.Debug.name()
    }
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
    }
    
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
    }
    
}
