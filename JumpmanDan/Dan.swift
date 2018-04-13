//
//  Dan.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/22/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class Dan: SKSpriteNode {
    
    //MARK: Variables
    private static let INITIAL_JUMP_FORCE: CGFloat = 75000
    private static let JUMP_DIVISOR: CGFloat = 1.5
    private static let YVELOCITY_RANGE: CGFloat = 10.0
    private static let INVINCIBILITY_TIME: Int = 1
    
    private var jumpForce: CGFloat = INITIAL_JUMP_FORCE
    private static let turnTextures = SKTextureAtlas(named: "Character Turn").textures
    private static let runTextures = SKTextureAtlas(named: "Character Run").textures
    
    private var touchingGround = false
    var powerNode: PowerSpawnNode
    var invincible: Bool = false
    var isActive: Bool = true
    var grounded: Bool {
        get {
            guard let yVelocity = physicsBody?.velocity.dy else { print("Cannot get player Y velocity"); return false }
            return touchingGround && yVelocity < Dan.YVELOCITY_RANGE && yVelocity > -Dan.YVELOCITY_RANGE
        }
        set(newGrounded) {
            touchingGround = newGrounded
        }
    }
    
    //MARK: - Initializers
    init(at pos: CGPoint, withScale scale: CGFloat, withPower powerType: PowerType?) {
        let texture = Dan.turnTextures[0]
        if let powerType = powerType {
            powerNode = PowerSpawnNode(powerType, withScale: scale)
        } else {
            powerNode = PowerSpawnNode(withScale: scale)
        }
        powerNode.position = pos
        super.init(texture: texture, color: .clear, size: texture.size())
        self.name = "Dan"
        self.zPosition = 10
        self.addChild(powerNode)
        self.position = pos
        self.setScale(scale)
        self.setupPhysics()
        self.initializeTextures()
    }
    
    convenience init(at pos: CGPoint, withScale scale: CGFloat) {
        self.init(at: pos, withScale: scale, withPower: nil)
    }
    
    //When using Dan from Scene Builder, setupPhysics() MUST be called separately, and dan node must be removed and re-added to scene
    required convenience init?(coder aDecoder: NSCoder) {
        let position = aDecoder.decodeObject(forKey: "position") as! CGPoint
        let scale = aDecoder.decodeObject(forKey: "scale") as! CGFloat
        let powerType = aDecoder.decodeObject(forKey: "powerType") as? PowerType
        self.init(at: position, withScale: scale, withPower: powerType)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(position, forKey: "position")
        aCoder.encode(xScale, forKey: "scale")
        aCoder.encode(powerNode.power?.type, forKey: "powerType")
    }
    
    //MARK: - Functions
    //Correct practice is to call beginJump() when a UITouch is registered, and continue calling jump for as long as that UITouch persists
    func beginJump() {
        run(.playSoundFileNamed("Jump", waitForCompletion: false), withKey: "jumpSound")
        grounded = false
        jumpForce = Dan.INITIAL_JUMP_FORCE
        jump()
    }
    
    func jump() {
        guard let physicsBody = physicsBody else { return }
        physicsBody.applyForce(CGVector(dx: 0, dy: jumpForce))
        jumpForce = jumpForce / Dan.JUMP_DIVISOR
    }
    
    func hop() {
        guard let physicsBody = physicsBody else { return }
        if self.isActive {
            isActive = false
            self.run(.wait(forDuration: 0.5)) {
                self.isActive = true
            }
            physicsBody.applyImpulse(CGVector(dx: 0, dy: Dan.INITIAL_JUMP_FORCE / 16))
        }
    }
    
    func hit() {
        guard let physicsBody = physicsBody else { return }
        if !invincible && self.isActive {
            physicsBody.applyImpulse(CGVector(dx: 0, dy: Dan.INITIAL_JUMP_FORCE / 32))
            self.run(.sequence([.playSoundFileNamed("DanHit", waitForCompletion: false), .moveBy(x: -20, y: 0, duration: 0.5)]))
            invincible = true
            isActive = false
            self.run(.wait(forDuration: 0.5)) {
                self.isActive = true
            }
            self.run(.repeat(.sequence([.fadeAlpha(to: 0, duration: 0.1), .fadeAlpha(to: 1, duration: 0.1)]), count: Dan.INVINCIBILITY_TIME * 10)) {
                self.invincible = false
            }
        }
    }
    
    func turn(onCompletion completionHandler: @escaping () -> Void ) {
        run(.animate(with: Dan.turnTextures, timePerFrame: 0.1), completion: completionHandler)
    }
    
    func stopRunning() {
        removeAction(forKey: "run")
        let turnBack: [SKTexture] = Dan.turnTextures.reversed()
        run(.animate(with: turnBack, timePerFrame: 0.1), withKey: "turnBack")
    }
    
    func run() {
        run(.repeatForever(.animate(with: Dan.runTextures, timePerFrame: 0.1)), withKey: "run")
    }
    
    //MARK: Private helper functions
    private func setupPhysics() {
        //Full physics body
        let rect = CGSize(width: 16 * xScale, height: 26 * yScale)
        
        let path = CGMutablePath()
        let cornerDistance: CGFloat = 2.0
        let points: [CGPoint] =
            [CGPoint(x: -rect.width / 2,                    y:  rect.height / 2),
             CGPoint(x:  rect.width / 2,                    y:  rect.height / 2),
             CGPoint(x:  rect.width / 2,                    y: -rect.height / 2 + cornerDistance),
             CGPoint(x:  rect.width / 2 - cornerDistance,   y: -rect.height / 2),
             CGPoint(x: -rect.width / 2 + cornerDistance,   y: -rect.height / 2),
             CGPoint(x: -rect.width / 2,                    y: -rect.height / 2 + cornerDistance)]
        path.addLines(between: points)
        path.closeSubpath()
        
        let physics = SKPhysicsBody(rectangleOf: rect)
        physics.isDynamic = true
        physics.allowsRotation = false
        physics.pinned = false
        physics.affectedByGravity = true
        physics.friction = 0
        physics.restitution = 0
        physics.angularDamping = 0
        physics.mass = 10
        physics.categoryBitMask = CategoryBitmask.Player.rawValue
        physics.collisionBitMask = CategoryBitmask.Ground.rawValue
        physics.contactTestBitMask = CategoryBitmask.Enemy.rawValue
        physics.usesPreciseCollisionDetection = true
        
        physicsBody = physics
        
        //Foot physics
        let node = SKNode()
        node.name = "DanFeet"
        
        let footPhysics = SKPhysicsBody(rectangleOf: CGSize(width: rect.width / 2 - 4, height: 2), center: CGPoint(x: 0, y: -rect.height / 4))
        footPhysics.isDynamic = true
        footPhysics.allowsRotation = false
        footPhysics.pinned = true
        footPhysics.affectedByGravity = false
        footPhysics.friction = 0
        footPhysics.restitution = 0
        footPhysics.linearDamping = 0
        footPhysics.angularDamping = 0
        footPhysics.categoryBitMask = 0
        footPhysics.collisionBitMask = 0
        footPhysics.contactTestBitMask = CategoryBitmask.Ground.rawValue + CategoryBitmask.Enemy.rawValue
        
        node.physicsBody = footPhysics
        addChild(node)
    }
    
    private func initializeTextures() {
        guard let texture = self.texture else { return }
        for texture in Dan.turnTextures + Dan.runTextures + [texture] {
            texture.filteringMode = .nearest
        }
    }
    
}
