//
//  PauseScreen.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/23/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class PauseScreen: SKScene {
    
    override func sceneDidLoad() {
        (childNode(withName: "Dan") as! SKSpriteNode).texture?.filteringMode = .nearest
        (childNode(withName: "Weapon Box/Sword") as! SKSpriteNode).texture?.filteringMode = .nearest
    }
    
}
