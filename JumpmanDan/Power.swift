//
//  Power.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 5/19/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

class PowerSpawnNode: SKNode {
    var power: Power?
    var spawnedNodes: [SKSpriteNode]
    
    init(_ powerType: PowerType?, withScale scale: CGFloat) {
        spawnedNodes = []
        super.init()
        self.name = "PowerSpawnNode"
        self.setScale(scale)
        if let powerType = powerType {
            set(to: powerType)
            power!.image.filteringMode = .nearest
        }
    }
    
    convenience init(_ powerType: PowerType) {
        self.init(powerType, withScale: 1.0)
    }
    
    convenience init(withScale scale: CGFloat) {
        self.init(nil, withScale: scale)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let powerType = aDecoder.decodeObject(forKey: "powerType") as? PowerType
        let scale = aDecoder.decodeObject(forKey: "scale") as! CGFloat
        self.init(powerType, withScale: scale)
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(power?.type, forKey: "powerType")
        aCoder.encode(xScale, forKey: "scale")
    }
    
    func set(to powerType: PowerType) {
        power = getPowerFrom(powerType: powerType)
    }
    
    func spawn() -> SKSpriteNode? {
        guard let parentPosition = parent?.position else { fatalError("PowerSpawn is not child of Dan") }
        self.position = parentPosition
        if let power = power {
            let node = power.createNode()
            node.position = self.position
            spawnedNodes.append(node)
            return node
        } else {
            return nil
        }
    }
    
    func destroy(nodes: [SKSpriteNode]) {
        for nodeToRemove in nodes {
            for (index, node) in spawnedNodes.enumerated().reversed() {
                if nodeToRemove == node {
                    spawnedNodes.remove(at: index)
                    node.removeFromParent()
                }
            }
        }
    }
    
    private func getPowerFrom(powerType: PowerType) -> Power {
        switch powerType {
        case .Fireball:
            return Fireball(withScale: xScale)
        case .Iceball:
            return Iceball(withScale: xScale)
        }
    }
}

protocol Power {
    var type: PowerType { get }
    var scale: CGFloat { get set }
    var image: SKTexture { get }
    var lifetime: TimeInterval { get }
    var damage: Double { get }
    
    func createNode() -> SKSpriteNode
}

class Fireball: Power {
    var type: PowerType = .Fireball
    var scale: CGFloat = 1.0
    var image = SKTexture(imageNamed: "Fireball")
    var lifetime: TimeInterval = 2.0
    var damage = 5.5
    
    init(withScale scale: CGFloat) {
        self.scale = scale
    }
    
    convenience init() {
        self.init(withScale: 1.0)
    }
    
    func createNode() -> SKSpriteNode {
        let spriteSize = CGSize(width: image.size().width * scale, height: image.size().height * scale)
        
        let spriteNode = SKSpriteNode(texture: image, color: UIColor.red, size: spriteSize)
        spriteNode.name = PowerType.Fireball.rawValue
        spriteNode.zPosition = 10
        let physicsBody = SKPhysicsBody(circleOfRadius: spriteSize.width / 2)
        physicsBody.angularDamping = 50
        physicsBody.linearDamping = 0
        physicsBody.velocity = CGVector(dx: 750, dy: 0)
        physicsBody.restitution = 0.9
        physicsBody.mass = 10
        physicsBody.categoryBitMask = CategoryBitmask.Power.rawValue
        physicsBody.collisionBitMask = CategoryBitmask.Ground.rawValue
        physicsBody.contactTestBitMask = CategoryBitmask.Ground.rawValue + CategoryBitmask.Enemy.rawValue
        spriteNode.physicsBody = physicsBody
        
        spriteNode.run(.rotate(toAngle: 1000, duration: lifetime, shortestUnitArc: false))
        spriteNode.run(.fadeOut(withDuration: lifetime)) {
            spriteNode.removeFromParent()
        }
        spriteNode.run(.playSoundFileNamed("Selection", waitForCompletion: false))
        
        return spriteNode
    }
}

class Iceball: Power {
    var type: PowerType = .Iceball
    var scale: CGFloat = 1.0
    var image = SKTexture(imageNamed: "Iceball")
    var lifetime: TimeInterval = 2.0
    var damage: Double = 0
    
    init(withScale scale: CGFloat) {
        self.scale = scale
    }
    
    convenience init() {
        self.init(withScale: 1.0)
    }
    
    func createNode() -> SKSpriteNode {
        let spriteSize = CGSize(width: image.size().width * scale, height: image.size().height * scale)
        
        let spriteNode = SKSpriteNode(texture: image, color: UIColor.red, size: spriteSize)
        spriteNode.name = PowerType.Iceball.rawValue
        spriteNode.zPosition = 10
        let physicsBody = SKPhysicsBody(circleOfRadius: spriteSize.width / 2)
        physicsBody.angularDamping = 50
        physicsBody.linearDamping = 0
        physicsBody.velocity = CGVector(dx: 500, dy: 0)
        physicsBody.restitution = 0.9
        physicsBody.mass = 10
        physicsBody.categoryBitMask = CategoryBitmask.Power.rawValue
        physicsBody.collisionBitMask = CategoryBitmask.Ground.rawValue
        physicsBody.contactTestBitMask = CategoryBitmask.Ground.rawValue + CategoryBitmask.Enemy.rawValue
        spriteNode.physicsBody = physicsBody
        
        spriteNode.run(.rotate(toAngle: 500, duration: lifetime, shortestUnitArc: false))
        spriteNode.run(.fadeOut(withDuration: lifetime)) {
            spriteNode.removeFromParent()
        }
        spriteNode.run(.playSoundFileNamed("Error", waitForCompletion: false))
        
        return spriteNode
    }
}

enum PowerType: String {
    case Fireball = "Fireball",
    Iceball = "Iceball"
}
