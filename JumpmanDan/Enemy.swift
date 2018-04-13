//
//  Enemy.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 5/27/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

protocol Enemy {
    var health: Double { get }
    var moving: Bool { get }
    var isActive: Bool { get }
    
    func startMoving()
    func freeze()
    func takeDamage(amount damage: Double)
}

class SKEnemy: SKSpriteNode {
    var isActive: Bool = true
    
    func flashRed() {
        let flashRed = SKAction.sequence([.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.25), .colorize(with: .red, colorBlendFactor: 0, duration: 0.25)])
        self.run(flashRed, withKey: "damage")
        self.run(.playSoundFileNamed("Die", waitForCompletion: false))
    }
    
    func turnBlue() {
        let color = UIColor(red: 102, green: 255, blue: 255, alpha: 1.0)
        self.run(.colorize(with: color, colorBlendFactor: 0.8, duration: 0.25))
        self.isActive = false
    }
    
    func die() {
        let particles = SKEmitterNode(fileNamed: "Death")!
        self.addChild(particles)
        self.isActive = false
        self.run(.fadeAlpha(to: 0, duration: 0.5)) {
            self.removeFromParent()
        }
    }
    func pause() {
        action(forKey: "animate")?.speed = 0
        action(forKey: "move")?.speed = 0
    }
    
    func unpause() {
        action(forKey: "animate")?.speed = 1
        action(forKey: "move")?.speed = 1
    }
    
    func freeze() {
        action(forKey: "animate")?.speed = 0
        action(forKey: "move")?.speed = 0
        self.physicsBody?.categoryBitMask = CategoryBitmask.Ground.rawValue
        self.physicsBody?.collisionBitMask = CategoryBitmask.Ground.rawValue + CategoryBitmask.Player.rawValue
        self.physicsBody?.contactTestBitMask = CategoryBitmask.Ground.rawValue
        turnBlue()
    }
}

class EvilCube: SKEnemy, Enemy {
    var health: Double = 5.0
    private let turnSprites = SKTextureAtlas(named: "Cube Turn")
    private let trail: SKEmitterNode
    var moving: Bool
    
    init(atPosition position: CGPoint, withScale scale: CGFloat) {
        trail = SKEmitterNode(fileNamed: "CubeTrail")!
        
        moving = false
        let texture = SKTexture(imageNamed: "Cube1")
        texture.filteringMode = .nearest
        super.init(texture: texture, color: .clear, size: texture.size())
        for texture in turnSprites.textures {
            texture.filteringMode = .nearest
        }
        trail.position = CGPoint(x: self.size.width / 2, y: -self.size.height / 2)
        self.name = "Enemy"
        self.position = position
        self.xScale = scale
        self.yScale = scale
        self.zPosition = 2
        
        let scaledTextureSize = CGSize(width: texture.size().width * scale, height: texture.size().height * scale)
        let physics = SKPhysicsBody(rectangleOf: scaledTextureSize)
        physics.restitution = 0
        physics.allowsRotation = false
        physics.friction = 0
        physics.angularDamping = 0
        physics.linearDamping = 0
        physics.mass = 100
        physics.categoryBitMask = CategoryBitmask.Enemy.rawValue
        physics.collisionBitMask = CategoryBitmask.Ground.rawValue
        physics.contactTestBitMask = CategoryBitmask.Player.rawValue + CategoryBitmask.Power.rawValue
        self.physicsBody = physics
        
        let hitbox = SKPhysicsBody(rectangleOf: CGSize(width: scaledTextureSize.width / 2, height: 3 * scale), center: CGPoint(x: 0, y: scaledTextureSize.height / 4))
        hitbox.affectedByGravity = false
        hitbox.pinned = true
        hitbox.allowsRotation = false
        hitbox.categoryBitMask = CategoryBitmask.Enemy.rawValue
        hitbox.collisionBitMask = 0
        hitbox.contactTestBitMask = CategoryBitmask.Player.rawValue
        
        let node = SKNode()
        node.name = "Hitbox"
        node.physicsBody = hitbox
        self.addChild(node)
        
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let position = aDecoder.decodeObject(forKey: "position") as! CGPoint
        let scale = aDecoder.decodeObject(forKey: "scale") as! CGFloat
        self.init(atPosition: position, withScale: scale)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(self.position, forKey: "position")
        aCoder.encode(self.xScale, forKey: "scale")
    }
    
    func startMoving() {
        moving = true
        let cubeMove = SKAction.repeatForever(.sequence([.scaleX(by: 0.8, y: 1.25, duration: 1), .scaleX(by: 1.25, y: 0.8, duration: 1)]))
        self.run(.animate(with: turnSprites.textures, timePerFrame: 0.05)) {
            self.run(cubeMove, withKey: "animate")
            self.addChild(self.trail)
            self.run(.repeatForever(.moveBy(x: -50, y: 0, duration: 1)), withKey: "move")
        }
    }
    
    override func freeze() {
        super.freeze()
        trail.removeFromParent()
    }
    
    func takeDamage(amount damage: Double) {
        health -= damage
        super.flashRed()
        if health <= 0 {
            self.die()
        }
    }
}
