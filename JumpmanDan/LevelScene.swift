//
//  LevelScene.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/22/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class LevelScene: SKScene, SKPhysicsContactDelegate {
    
    //MARK: - Variables
    
    //MARK: Subclass-overriding variables
    var LEVEL_SPEED: CGFloat {
        get {
            return 0
        }
    }
    
    var LEVEL_NAME: String {
        get {
            return ""
        }
    }
    
    //MARK: Level nodes
    var dan: Dan!
    var power: PowerType?
    var tileMap: SKTileMapNode!
    var backgroundMusic: SKAudioNode!
    var background: SKSpriteNode!
    var parallaxBackgrounds = [SKNode]()
    var sceneCamera: SKCameraNode!
    var originalCameraPosition: CGPoint = CGPoint.zero
    var finish: SKSpriteNode!
    var confetti: SKEmitterNode!
    
    //MARK: HUD nodes
    var hud: SKNode!
    var pauseButton: SKNode!
    var overlay: SKShapeNode!
    var tapToStart = SKLabelNode(text: "TAP TO START")
    
    //MARK: Pause screen nodes
    var pauseScreen: SKReferenceNode!
    var resumeButton: SKNode!
    var exitButton: SKNode!
    var restartButton: SKNode!
    var optionsButton: SKNode!
    var powerIcon: SKSpriteNode!
    var powerName: SKLabelNode!
    
    //MARK: Other variables
    
    var jumpTouch: UITouch?
    var state = LevelState.tapToStart
    
    //MARK: - Functions
    override func sceneDidLoad() {
        scaleMode = .fill
        
        //MARK: Node initialization
        
        //Level
        let danNode = childNode(withName: "Dan") as! SKSpriteNode
        dan = Dan(at: danNode.position, withScale: danNode.xScale)
        
        tileMap = childNode(withName: "Tile Map") as! SKTileMapNode
        backgroundMusic = childNode(withName: "Background Music") as! SKAudioNode
        background = childNode(withName: "Background") as! SKSpriteNode
        sceneCamera = childNode(withName: "Camera") as! SKCameraNode
        originalCameraPosition = sceneCamera.position
        finish = childNode(withName: "Finish") as! SKSpriteNode
        finish.texture?.filteringMode = .nearest
        confetti = SKEmitterNode(fileNamed: "Confetti")
        confetti.zPosition = 100
        tileMap.filteringMode = .nearest
        
        //HUD
        hud = childNode(withName: "HUD")
        pauseButton = hud.childNode(withName: "SKNode/Pause Button")
        overlay = SKShapeNode(rectOf: self.size)
        overlay.position = dan.position
        overlay.strokeColor = .black
        overlay.fillColor = .black
        overlay.zPosition = 100
        overlay.alpha = 0.5
        tapToStart.fontName = "Helvetica Neue Condensed Bold"
        tapToStart.fontSize = 96
        tapToStart.setScale(0.5)
        tapToStart.fontColor = UIColor.white
        tapToStart.verticalAlignmentMode = .center
        tapToStart.position = dan.position
        tapToStart.zPosition = 101
        
        //Pause
        guard let pathToPauseScreen = Bundle.main.path(forResource: "PauseScreen", ofType: "sks") else {
            fatalError("Pause screen not found")
        }
        pauseScreen = SKReferenceNode(url: URL(fileURLWithPath: pathToPauseScreen))
        pauseScreen.name = "Pause Screen"
    }
    
    override func didMove(to view: SKView) {
        childNode(withName: "Dan")?.removeFromParent()
        if let power = power {
            dan.powerNode.set(to: power)
        }
        addChild(dan)
        
        enumerateChildNodes(withName: "Parallax *") {
            (node, _) in
            if let name = node.name {
                guard let index = Int(name.substring(from: name.index(before: name.endIndex))) else {
                    fatalError("Parallax node name not formatted correctly")
                }
                
                if let tileMapNode = node as? SKTileMapNode {
                    tileMapNode.filteringMode = .nearest
                }
                self.parallaxBackgrounds.insert(node, at: index)
            }
        }
        
        tileMap.enumerateChildNodes(withName: "Cube") {
            (node, _) in
            let pos = self.convert(node.position, from: self.tileMap)
            let cube = EvilCube(atPosition: pos, withScale: self.tileMap.xScale)
            self.addChild(cube)
            node.removeFromParent()
        }
        
        if defaults.bool(forKey: "muteMusic") == true {
            backgroundMusic.run(.changeVolume(to: 0, duration: 0))
        }
        
        //HUD
        addChild(overlay)
        addChild(tapToStart)
        
        //Pause
        resumeButton = pauseScreen.childNode(withName: "SKNode/Resume Button")
        exitButton = pauseScreen.childNode(withName: "SKNode/Exit Button")
        restartButton = pauseScreen.childNode(withName: "SKNode/Restart Button")
        optionsButton = pauseScreen.childNode(withName: "SKNode/Options Button")
        powerIcon = pauseScreen.childNode(withName: "SKNode/Weapon Box/Sword") as! SKSpriteNode
        powerName = pauseScreen.childNode(withName: "SKNode/Weapon Name") as! SKLabelNode
        addChild(pauseScreen)
        
        //Scene setup
        tileMap.initializePhysicsBody()
        physicsWorld.contactDelegate = self
        sceneCamera.setScale(0.5)
        sceneCamera.position = dan.position
        pauseScreen.position = CGPoint(x: sceneCamera.position.x, y: self.size.height)
        tapToStart.run(.repeatForever(.sequence([ .wait(forDuration: 0.5), .unhide(), .wait(forDuration: 0.5), .hide() ])), withKey: "blink")
        powerIcon.texture = dan.powerNode.power?.image
        powerIcon.texture?.filteringMode = .nearest
        powerName.text = dan.powerNode.power?.type.rawValue.uppercased()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPosition = touch.location(in: sceneCamera)
            
            switch state {
            case .tapToStart:
                if overlay.action(forKey: "fade") == nil {
                    tapToStart.removeAction(forKey: "blink")
                    tapToStart.isHidden = true
                    sceneCamera.run(.scale(to: 1, duration: 0.5))
                    sceneCamera.run(.moveTo(y: originalCameraPosition.y, duration: 0.5))
                    overlay.run(.wait(forDuration: 0.85), withKey: "fade")
                    overlay.run(.fadeOut(withDuration: 0.5)) {
                        self.dan.turn {
                            self.state = .playing
                            self.dan.run()
                            self.backgroundMusic.autoplayLooped = true
                            self.backgroundMusic.run(.play())
                        }
                    }
                }
            case .playing:
                if pauseButton.contains(touchPosition) && sceneCamera.action(forKey: "unpause") == nil {
                    //Pause the game
                    pauseButton.run(PUSH_BUTTON_FORWARD)
                    state = .paused
                    freeze()
                    sceneCamera.run(.moveTo(y: pauseScreen.position.y, duration: 1), withKey: "pause")
                    enumerateChildNodes(withName: "Enemy") {
                        (node, _) in
                        if let node = node as? SKEnemy {
                            node.pause()
                        }
                    }
                } else {
                    if touchPosition.x > 0 { //Right side of the screen was tapped
                        if dan.grounded && jumpTouch == nil {
                            jumpTouch = touch
                            dan.beginJump()
                        }
                    } else { //Left side of the screen was tapped
                        if dan.powerNode.spawnedNodes.count < 3 {
                            if let node = dan.powerNode.spawn() {
                                addChild(node)
                            }
                        }
                    }
                }
            case .paused:
                if sceneCamera.action(forKey: "pause") == nil {
                    if resumeButton.contains(touchPosition) {
                        //Unpause the game
                        resumeButton.run(PUSH_BUTTON_FORWARD)
                        sceneCamera.run(.moveTo(y: background.position.y, duration: 1), completion: {
                            self.unfreeze()
                            self.state = .playing
                            self.enumerateChildNodes(withName: "Enemy") {
                                (node, _) in
                                if let node = node as? SKEnemy {
                                    node.unpause()
                                }
                            }
                        })
                    }
                    
                    if exitButton.contains(touchPosition) {
                        exitButton.run(PUSH_BUTTON_BACKWARD, completion: {
                            if let titleScreen = SKScene(fileNamed: "TitleScreen") {
                                self.view?.presentScene(titleScreen, transition: .push(with: .up, duration: 1))
                            }
                        })
                    }
                    
                    if restartButton.contains(touchPosition) {
                        restartButton.run(PUSH_BUTTON_BACKWARD, completion: {
                            guard let level = SKScene(fileNamed: self.LEVEL_NAME) as? LevelScene else { fatalError("Level name not set") }
                            if let powerType = self.dan.powerNode.power?.type {
                                level.power = powerType
                            }
                            self.view?.presentScene(level, transition: .fade(withDuration: 2))
                        })
                    }
                }
            case .complete:
                if let weaponsScreen = SKScene(fileNamed: "LevelSelect") {
                    view?.presentScene(weaponsScreen, transition: .fade(withDuration: 2))
                }
            case .gameOver:
                if let weaponsScreen = SKScene(fileNamed: "LevelSelect") {
                    view?.presentScene(weaponsScreen, transition: .fade(withDuration: 2))
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if state == .playing {
                if touch == jumpTouch {
                    jumpTouch = nil
                }
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if state == .playing {
                if touch == jumpTouch {
                    dan.removeAction(forKey: "jumpSound")
                    jumpTouch = nil
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let screenSize = self.size
        
        if state == .playing {
            if dan.position.x + dan.size.width / 2 < sceneCamera.position.x - self.size.width / 2 || dan.position.y + dan.size.height / 2 < sceneCamera.position.y - self.size.height / 2{
                //MARK: Game Over
                state = .gameOver
                self.backgroundMusic.run(.changeVolume(to: 0, duration: 1.0))
                self.run(.playSoundFileNamed("GameOver", waitForCompletion: false))
                overlay.position = sceneCamera.position
                overlay.run(.fadeIn(withDuration: 2))
                tapToStart.position = sceneCamera.position
                tapToStart.text = "GAME OVER"
                tapToStart.setScale(1)
                tapToStart.alpha = 0
                tapToStart.isHidden = false
                tapToStart.run(.fadeIn(withDuration: 2))
                return
            }
            
            if finish.contains(dan.position) {
                //MARK: Stage Complete
                state = .complete
                freeze()
                dan.stopRunning()
                backgroundMusic.run(.changeVolume(to: 0, duration: 0.5)) {
                    self.sceneCamera.run(.move(to: self.dan.position, duration: 1))
                    self.sceneCamera.run(.scale(to: 0.5, duration: 1))
                    let particles1 = self.confetti.copy() as! SKEmitterNode
                    let particles2 = self.confetti.copy() as! SKEmitterNode
                    particles1.position = CGPoint(x: -screenSize.width / 4, y: -screenSize.height / 2)
                    particles2.position = CGPoint(x: screenSize.width / 4, y: -screenSize.height / 2)
                    self.sceneCamera.addChild(particles1)
                    self.sceneCamera.addChild(particles2)
                    particles1.run(.sequence([.wait(forDuration: 5), .removeFromParent()]))
                    particles2.run(.sequence([.wait(forDuration: 5), .removeFromParent()]))
                    self.finish.run(.playSoundFileNamed("Stage_Complete", waitForCompletion: true)) {
                        
                    }
                }
            }
            
            dan.position.x += LEVEL_SPEED
            sceneCamera.position.x += LEVEL_SPEED
            
            if dan.position.y > 0 {
                sceneCamera.position.y = dan.position.y
            }
            
            pauseScreen.position = CGPoint(x: sceneCamera.position.x, y: screenSize.height + sceneCamera.position.y)
            
            var speed = LEVEL_SPEED
            for bg in parallaxBackgrounds {
                speed = speed / 2
                bg.position.x += speed
            }
            
            if jumpTouch != nil {
                dan.jump()
            }
            
            var nodesToRemove = [SKSpriteNode]()
            for node in dan.powerNode.spawnedNodes {
                let nodePosition = convertPoint(toView: node.position)
                if nodePosition.x < 0 || nodePosition.x > screenSize.width {
                    nodesToRemove.append(node)
                }
            }
            dan.powerNode.destroy(nodes: nodesToRemove)
            
            enumerateChildNodes(withName: "Enemy") {
                (node, _) in
                if let node = node as? EvilCube {
                    let nodePositionInCamera = self.sceneCamera.convert(node.position, from: self)
                    let nodeInView = nodePositionInCamera.x < screenSize.width / 2 && nodePositionInCamera.x > -screenSize.width / 2 && nodePositionInCamera.y < screenSize.width / 2 && nodePositionInCamera.y > -screenSize.width / 2
                    if node.moving == false && nodeInView {
                        node.startMoving()
                    }
                }
            }
            
        }
        if state != .paused {
            background.position = sceneCamera.position
            hud.position = sceneCamera.position
        }
        if state == .complete {
            background.position = sceneCamera.position
        }
    }
    
    //SKPhysicsContactDelegate hook
    func didBegin(_ contact: SKPhysicsContact) {
        
        if containsNodesNamed(collision: contact, "DanFeet", "Ground Physics") {
            dan.grounded = true
        }
        if containsNodesNamed(collision: contact, PowerType.Fireball.rawValue, "Ground Physics") {
            self.run(.playSoundFileNamed("FireBounce", waitForCompletion: false))
            if let fireball = getNode(fromCollision: contact, named: PowerType.Fireball.rawValue), let fire = SKEmitterNode(fileNamed: "Fire") {
                fire.position = fireball.position
                addChild(fire)
                fire.run(.wait(forDuration: 2)) {
                    fire.removeFromParent()
                }
            }
        }
        if containsNodesNamed(collision: contact, PowerType.Iceball.rawValue, "Ground Physics") {
            self.run(.playSoundFileNamed("IceBounce", waitForCompletion: false))
            if let iceball = getNode(fromCollision: contact, named: PowerType.Iceball.rawValue), let ice = SKEmitterNode(fileNamed: "Ice") {
                ice.position = iceball.position
                addChild(ice)
                ice.run(.wait(forDuration: 2)) {
                    ice.removeFromParent()
                }
            }
        }
        if containsNodesNamed(collision: contact, PowerType.Iceball.rawValue, "Liquid Physics") {
            if let iceball = getNode(fromCollision: contact, named: PowerType.Iceball.rawValue) {
                tileMap.freezeWater(atPosition: iceball.position)
            }
        }
        if containsNodesNamed(collision: contact, PowerType.Fireball.rawValue, "Enemy") {
            if let enemy = getNode(fromCollision: contact, named: "Enemy") as? Enemy, let fireball = getNode(fromCollision: contact, named: PowerType.Fireball.rawValue) as? SKSpriteNode {
                if enemy.isActive {
                    enemy.takeDamage(amount: Fireball().damage)
                    dan.powerNode.destroy(nodes: [fireball])
                }
            }
        }
        if containsNodesNamed(collision: contact, PowerType.Iceball.rawValue, "Enemy") {
            if let enemy = getNode(fromCollision: contact, named: "Enemy") as? Enemy, let iceball = getNode(fromCollision: contact, named: PowerType.Iceball.rawValue) as? SKSpriteNode {
                if enemy.isActive {
                    enemy.takeDamage(amount: Iceball().damage)
                    enemy.freeze()
                    dan.powerNode.destroy(nodes: [iceball])
                }
            }
        }
        if containsNodesNamed(collision: contact, "DanFeet", "Hitbox") {
            if let hitbox = getNode(fromCollision: contact, named: "Hitbox") , let enemy = hitbox.parent as? Enemy {
                if enemy.isActive && dan.isActive {
                    enemy.takeDamage(amount: 3.0)
                    dan.hop()
                }
            }
        }
        if containsNodesNamed(collision: contact, "Dan", "Enemy") {
            if let enemy = getNode(fromCollision: contact, named: "Enemy") as? Enemy {
                if enemy.isActive {
                    dan.hit()
                }
            }
        }
        
    }
    
    //Helper functions
    func freeze() {
        dan.action(forKey: "run")?.speed = 0
        physicsWorld.speed = 0
    }
    
    func unfreeze() {
        self.dan.action(forKey: "run")?.speed = 1
        self.physicsWorld.speed = 1.0
    }
    
    private func containsNodesNamed(collision: SKPhysicsContact, _ name1: String, _ name2: String) -> Bool {
        guard let nameA = collision.bodyA.node?.name, let nameB = collision.bodyB.node?.name else { return false }
        if nameA == name1 && nameB == name2 || nameB == name1 && nameA == name2 {
            return true
        }
        return false
    }
    
    private func getNode(fromCollision collision: SKPhysicsContact, named name: String) -> SKNode? {
        guard let nameA = collision.bodyA.node?.name, let nameB = collision.bodyB.node?.name else { return nil }
        if name == nameA {
            return collision.bodyA.node
        } else if name == nameB {
            return collision.bodyB.node
        }
        return nil
    }
    
}


//MARK: - Enums
enum LevelState {
    case tapToStart,
    playing,
    paused,
    complete,
    gameOver
}
