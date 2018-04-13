//
//  GameScene.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/20/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import SpriteKit
import GameplayKit

class TitleScreen: MenuScene {
    
    private var character: SKSpriteNode!
    
    private var playButton: SKNode!
    private var optionsButton: SKNode!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        character = childNode(withName: "Character") as! SKSpriteNode!
        character.texture?.filteringMode = .nearest
        
        playButton = childNode(withName: "Play Button")
        optionsButton = childNode(withName: "Options Button")
    }
    
    override func didMove(to view: SKView) {
    }
    
    func touchDown(atPoint pos : CGPoint) {
        if playButton.contains(pos) {
            playButton.run(PUSH_BUTTON_FORWARD, completion: {
                if let levelScreen = SKScene(fileNamed: "LevelSelect") {
                    self.goToScreen(levelScreen, withDirection: .left)
                } else {
                    fatalError("Could not find WeaponSelect")
                }
            })
        }
        
        if optionsButton.contains(pos) {
            optionsButton.run(PUSH_BUTTON_FORWARD, completion: {
                if let optionsScreen = SKScene(fileNamed: "OptionsScreen") {
                    self.goToScreen(optionsScreen, withDirection: .right)
                } else {
                    fatalError("Could not find OptionsScreen")
                }
            })
        } else if character.contains(pos) && character.action(forKey: "pop") == nil {
            character.run(.sequence([PUSH, .playSoundFileNamed("Jump.wav", waitForCompletion: false)]), withKey: "pop")
        }
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
    }
}
