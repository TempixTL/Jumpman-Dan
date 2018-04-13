//
//  WeaponSelect.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/21/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class WeaponSelect: MenuScene {
    
    var levelName: String?
    
    var inventoryIcons: [SKSpriteNode]!
    var equipped: SKSpriteNode!
    var character: SKSpriteNode!
    var selectedLabel: SKLabelNode!
    var selection: SKSpriteNode!
    
    var goButton: SKNode!
    var backButton: SKNode!
    
    var inventory = [Bool]()
    var selectedItem: Int = 0
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        inventoryIcons = [childNode(withName: "//Fireball") as! SKSpriteNode, childNode(withName: "//Iceball") as! SKSpriteNode, childNode(withName: "//Something idk") as! SKSpriteNode]
        equipped = childNode(withName: "Equipped Box/Icon") as! SKSpriteNode
        character = childNode(withName: "Character") as! SKSpriteNode
        selectedLabel = childNode(withName: "Power Name") as! SKLabelNode
        selection = childNode(withName: "Selection") as! SKSpriteNode
        selectedItem = defaults.integer(forKey: "selectedItem")
        
        goButton = childNode(withName: "Go Button")
        backButton = childNode(withName: "Back Button")
    }
    
    override func didMove(to view: SKView) {
        inventory = getUnlockedPowers()
        
        selection.position = inventoryIcons[selectedItem].parent!.position
        updateEquippedLabel()
        
        for (index, icon) in inventoryIcons.enumerated() {
            guard let parent = icon.parent else { break }
            guard let lockedIcon = parent.childNode(withName: "Locked") as? SKSpriteNode else { break }
            if inventory[index] {
                icon.texture?.filteringMode = .nearest
                lockedIcon.isHidden = true
            } else {
                icon.alpha = 0.5
                lockedIcon.texture?.filteringMode = .nearest
            }
        }
        
        equipped.texture?.filteringMode = .nearest
        character.texture?.filteringMode = .nearest
    }
    
    func touchDown(atPoint pos: CGPoint) {
        
        if goButton.contains(pos) {
            goButton.run(PUSH_BUTTON_FORWARD, completion: {
                defaults.set(self.selectedItem, forKey: "selectedItem")
                if let levelName = self.levelName, let levelScreen = SKScene(fileNamed: levelName) as? LevelScene {
                    levelScreen.power = self.getCurrentPower()
                    self.view?.presentScene(levelScreen, transition: .fade(with: .black, duration: 2))
                } else {
                    guard let level = Level(rawValue: defaults.integer(forKey: "lastSelectedLevel")), let levelScreen = SKScene(fileNamed: level.name()) as? LevelScene else { fatalError("Could not find level screen") }
                    levelScreen.power = self.getCurrentPower()
                    self.view?.presentScene(levelScreen, transition: .fade(with: .black, duration: 2))
                }
            })
        }
        
        if backButton.contains(pos) {
            backButton.run(PUSH_BUTTON_BACKWARD, completion: {
                if let levelSelect = SKScene(fileNamed: "LevelSelect") {
                    self.goToScreen(levelSelect, withDirection: .right)
                } else {
                    fatalError("Could not find TitleScreen SKScene")
                }
            })
        }
        
        for (index, power) in inventoryIcons.enumerated() {
            guard let box = power.parent else { break }
            if box.contains(pos) && selection.action(forKey: "move") == nil {
                if inventory[index] == true {
                    selection.run(.move(to: box.position, duration: 0.1), withKey: "move")
                    selection.run(.playSoundFileNamed("Selection", waitForCompletion: false))
                    selectedItem = index
                    updateEquippedLabel()
                } else {
                    let originalPosition = selection.position
                    selection.run(.sequence([.move(to: box.position, duration: 0.05), .playSoundFileNamed("Error", waitForCompletion: false), .move(to: originalPosition, duration: 0.05)]), withKey: "move")
                }
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    //MARK: Private helper functions
    
    private func updateEquippedLabel() {
        if let currentPower = getCurrentPower() {
            selectedLabel.text = currentPower.rawValue.uppercased()
            equipped.texture = inventoryIcons[selectedItem].texture
        } else {
            selectedLabel.text = "NONE"
            equipped.texture = SKTexture(imageNamed: "NoWeapon")
            equipped.texture?.filteringMode = .nearest
        }
    }
    
    private func getCurrentPower() -> PowerType? {
        if let powerName = inventoryIcons[selectedItem].name, let powerType = PowerType(rawValue: powerName) {
            return powerType
        } else {
            return nil
        }
    }
    
}
