//
//  OptionsScreen.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/21/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class OptionsScreen: MenuScene {
    
    var backButton: SKNode!
    
    var debugToggle: SKNode!
    var muteToggle: SKNode!
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        backButton = childNode(withName: "Back Button")
        
        debugToggle = childNode(withName: "Debug Option/Toggle")
        muteToggle = childNode(withName: "BG Music Option/Toggle")
    }
    
    override func didMove(to view: SKView) {
        updateToggles()
    }
    
    func touchDown(atPoint pos: CGPoint) {
        if debugToggle.contains(pos) {
            defaults.set(!defaults.bool(forKey: "debug"), forKey: "debug")
            
            debugToggle.run(PUSH_BUTTON_FORWARD)
            updateToggles()
        }
        if muteToggle.contains(pos) {
            defaults.set(!defaults.bool(forKey: "muteMusic"), forKey: "muteMusic")
            
            muteToggle.run(PUSH_BUTTON_FORWARD)
            updateToggles()
        }
        
        if backButton.contains(pos) {
            backButton.run(PUSH_BUTTON_BACKWARD, completion: {
                if let titleScreen = SKScene(fileNamed: "TitleScreen") {
                    self.goToScreen(titleScreen, withDirection: .left)
                } else {
                    fatalError("Could not find TitleScreen")
                }
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    private func updateToggles() {
        if let debugLabel = self.debugToggle.childNode(withName: "Text") as? SKLabelNode {
            if defaults.bool(forKey: "debug") == true {
                debugLabel.text = "ON"
            } else {
                debugLabel.text = "OFF"
            }
        }
        if let muteLabel = self.muteToggle.childNode(withName: "Text") as? SKLabelNode {
            if defaults.bool(forKey: "muteMusic") == true {
                muteLabel.text = "ON"
            } else {
                muteLabel.text = "OFF"
            }
        }
    }
    
}
