import SpriteKit
import Foundation

class LevelSelect: MenuScene {
    
    var backButton: SKNode!
    var nextButton: SKNode!
    
    var selection: SKSpriteNode!
    var debugLevel: SKNode!
    var level1: SKNode!
    var level2: SKNode!
    var level3: SKNode!
    
    var levelNodes: [SKNode] = []
    let unlockedLevels = getUnlockedLevels()
    var selectedLevel: Level = .One
    
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        backButton = childNode(withName: "Back Button")
        nextButton = childNode(withName: "Next Button")
        
        selection = childNode(withName: "Selection") as! SKSpriteNode
        debugLevel = childNode(withName: "Levels/Debug Level")
        level1 = childNode(withName: "Levels/Level 1")
        level2 = childNode(withName: "Levels/Level 2")
        level3 = childNode(withName: "Levels/Level 3")
    }
    
    override func didMove(to view: SKView) {
        if let level = Level(rawValue: defaults.integer(forKey: "lastSelectedLevel")) {
            selectedLevel = level
        }
        setSelectedLevel(level: selectedLevel)
        
        levelNodes = [debugLevel, level1, level2, level3]
        
        for (index, level) in levelNodes.enumerated() {
            
            if let lockedNode = level.childNode(withName: "Locked") as? SKSpriteNode {
                if self.unlockedLevels[index] {
                    lockedNode.isHidden = true
                } else {
                    lockedNode.texture?.filteringMode = .nearest
                }
            }
            
            if let imageNode = level.childNode(withName: "Image") as? SKSpriteNode {
                if self.unlockedLevels[index] == false {
                    imageNode.alpha = 0.5
                } else {
                    imageNode.texture?.filteringMode = .nearest
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            if backButton.contains(touchLocation) {
                backButton.run(PUSH_BUTTON_BACKWARD) {
                    if let titleScreen = SKScene(fileNamed: "TitleScreen") {
                        self.goToScreen(titleScreen, withDirection: .right)
                    }
                }
            } else if nextButton.contains(touchLocation) {
                defaults.set(selectedLevel.rawValue, forKey: "lastSelectedLevel")
                nextButton.run(PUSH_BUTTON_FORWARD) {
                    if let weaponSelect = SKScene(fileNamed: "WeaponSelect") as? WeaponSelect {
                        weaponSelect.levelName = self.selectedLevel.name()
                        self.goToScreen(weaponSelect, withDirection: .left)
                    }
                }
            }
            
            for (index, level) in levelNodes.enumerated() {
                if level.contains(touchLocation) && selection.action(forKey: "move") == nil {
                    if unlockedLevels[index] {
                        guard let newSelectedLevel = Level(rawValue: index) else { fatalError("Couldn't get level from selected level") }
                        selectedLevel = newSelectedLevel
                        selection.run(.sequence([.move(to: level.position, duration: 0.1), .playSoundFileNamed("Selection", waitForCompletion: false)]), withKey: "move")
                    } else {
                        let originalPosition = selection.position
                        selection.run(.sequence([ .move(to: level.position, duration: 0.05), .playSoundFileNamed("Error", waitForCompletion: false), .move(to: originalPosition, duration: 0.05) ]), withKey: "move")
                    }
                }
            }
        }
    }
    
    //MARK: Private helper functions
    
    func setSelectedLevel(level: Level) {
        
        switch level {
        case .Debug:
            selection.position = debugLevel.position
        case .One:
            selection.position = level1.position
        case .Two:
            selection.position = level2.position
        case .Three:
            selection.position = level3.position
        }
        
    }
    
}

enum Level: Int {
    case Debug = 0,
    One = 1,
    Two = 2,
    Three = 3
    func name() -> String {
        switch self {
        case .Debug:
            return "LevelTest"
        case .One:
            return "Level1"
        case .Two:
            return "Level2"
        case .Three:
            return "Level3"
        }
    }
}
