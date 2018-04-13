//
//  MenuScene.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/23/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class MenuScene: SKScene {
    
    override func sceneDidLoad() {
        scaleMode = .aspectFit
    }
    
    func goToScreen(_ scene: SKScene, withDirection direction: SKTransitionDirection) {
        view?.presentScene(scene, transition: .push(with: direction, duration: 0.5))
    }
    
}
