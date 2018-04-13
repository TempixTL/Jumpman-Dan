//
//  Helper.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/21/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import Foundation
import SpriteKit

let PUSH: SKAction = SKAction.sequence([.scale(by: 0.8, duration: 0.1), .scale(by: 1.25, duration: 0.1)])
let PUSH_BUTTON_FORWARD: SKAction = SKAction.sequence([.playSoundFileNamed("Button_High", waitForCompletion: false), .scale(by: 0.8, duration: 0.1), .scale(by: 1.25, duration: 0.1)])
let PUSH_BUTTON_BACKWARD: SKAction = SKAction.sequence([.playSoundFileNamed("Button_Low", waitForCompletion: false), .scale(by: 0.8, duration: 0.1), .scale(by: 1.25, duration: 0.1)])
let defaults = UserDefaults.standard

enum CategoryBitmask: UInt32 {
    case Water  = 0b10000
    case Ground = 0b01000
    case Power  = 0b00100
    case Enemy  = 0b00010
    case Player = 0b00001
}

extension SKTextureAtlas {
    var textures: [SKTexture] {
        get {
            var textures = [SKTexture]()
            
            for name in self.textureNames.sorted() {
                textures.append(self.textureNamed(name))
            }
            
            return textures
        }
    }
}

extension SKTileMapNode {
    
    var filteringMode: SKTextureFilteringMode {
        get {
            if let filteringMode = self.tileSet.defaultTileGroup?.rules[0].tileDefinitions[0].textures[0].filteringMode {
                return filteringMode
            } else {
                return .linear
            }
        }
        set(mode) {
            for group in self.tileSet.tileGroups {
                for rule in group.rules {
                    for definition in rule.tileDefinitions {
                        for texture in definition.textures {
                            texture.filteringMode = mode
                        }
                    }
                }
            }
        }
    }
    
    private func findTilesWithUserData(named name: String) -> [(Int, Int)] {
        var tiles = [(Int, Int)]()
        for row in 0 ..< self.numberOfRows {
            for column in 0 ..< self.numberOfColumns {
                if self.tileDefinition(atColumn: column, row: row)?.userData?[name] != nil {
                    tiles.append((row, column))
                }
            }
        }
        return tiles
    }
    
    private func getPhysicsBodyFrom(tiles: [(Int, Int)]) -> SKPhysicsBody {
        var physicsBodies = [SKPhysicsBody]()
        for (row, column) in tiles {
            physicsBodies.append(SKPhysicsBody(rectangleOf: self.tileSize, center: self.centerOfTile(atColumn: column, row: row)))
        }
        return SKPhysicsBody(bodies: physicsBodies)
    }
    
//    private func getPhysicsBodyFrom(tiles: [[Bool]]) -> SKPhysicsBody {
//        var physicsBodies = [SKPhysicsBody]()
//        let falseColumns = Array(repeating: false, count: self.numberOfColumns)
//        var tileHasBody = Array(repeating: falseColumns, count: self.numberOfRows)
//        for (rowIndex, row) in tiles.enumerated() {
//            for (columnIndex, column) in row.enumerated() {
//                if tileHasBody[rowIndex][columnIndex] == false && tiles[rowIndex][columnIndex] == true {
//                    print("Row: \(rowIndex), column: \(columnIndex)")
//                    print("Tile does not already have body")
//                    var tileColumnsToCombine = [columnIndex]
//                    tileHasBody[rowIndex][columnIndex] = true
//                    for index in columnIndex..<row.count {
//                        if tiles[rowIndex][index] {
//                            print("adding tile at row \(rowIndex) and column \(index)")
//                            tileColumnsToCombine.append(index)
//                            tileHasBody[rowIndex][index] = true
//                        } else {
//                            print("breaking")
//                            break
//                        }
//                    }
//                    let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: CGFloat(tileColumnsToCombine.count) * self.tileSize.width, height: self.tileSize.height), center: CGPoint(x: (CGFloat(rowIndex) * self.tileSize.width) + (CGFloat(tileColumnsToCombine.count) * self.tileSize.width / 2), y: self.centerOfTile(atColumn: columnIndex, row: rowIndex).y ))
//                    print("PhysicsBody created: \(physicsBody)")
//                    physicsBodies.append(physicsBody)
//                }
//            }
//        }
//        return SKPhysicsBody(bodies: physicsBodies)
//    }
    
    private func getPhysicsBodyFrom(userData: String) -> SKPhysicsBody {
        return getPhysicsBodyFrom(tiles: findTilesWithUserData(named: userData))
    }
    
    private func getGroundPhysicsBody() -> SKPhysicsBody {
        var physicsBodies = [SKPhysicsBody]()
        for row in 0 ..< self.numberOfRows {
            for column in 0 ..< self.numberOfColumns {
                if self.tileDefinition(atColumn: column, row: row)?.userData?["top"] != nil {
                    let size = CGSize(width: self.tileSize.width, height: self.tileSize.height - 2)
                    let center = CGPoint(x: self.centerOfTile(atColumn: column, row: row).x, y: self.centerOfTile(atColumn: column, row: row).y - 1)
                    physicsBodies.append(SKPhysicsBody(rectangleOf: size, center: center))
                } else if self.tileDefinition(atColumn: column, row: row)?.userData?["edge"] != nil {
                    physicsBodies.append(SKPhysicsBody(rectangleOf: self.tileSize, center: self.centerOfTile(atColumn: column, row: row)))
                }
            }
        }
        return SKPhysicsBody(bodies: physicsBodies)
    }
    
    //In order for this to work, edge tile definitions must be marked as "edge"
    private func createPhysicsBody() -> SKPhysicsBody {
        let body = getGroundPhysicsBody()
        body.affectedByGravity = false
        body.isDynamic = true
        body.mass = CGFloat(Int.max)
        body.allowsRotation = false
        body.pinned = true
        body.restitution = 0
        body.categoryBitMask = CategoryBitmask.Ground.rawValue
        body.collisionBitMask = CategoryBitmask.Player.rawValue + CategoryBitmask.Enemy.rawValue + CategoryBitmask.Power.rawValue
        body.contactTestBitMask = CategoryBitmask.Ground.rawValue
        
        return body
    }
    
    private func createWaterPhysics() -> SKPhysicsBody {
        let splashTiles = findTilesWithUserData(named: "splash")
        for (row, column) in splashTiles {
            let position = self.centerOfTile(atColumn: column, row: row)
            if let splashes = SKEmitterNode(fileNamed: "Splash") {
                splashes.name = "Splash"
                splashes.zPosition = 1
                splashes.position = position
                self.addChild(splashes)
            }
        }
        
        let body = getPhysicsBodyFrom(userData: "water")
        body.affectedByGravity = false
        body.isDynamic = true
        body.mass = CGFloat(Int.max)
        body.allowsRotation = false
        body.pinned = true
        body.restitution = 0
        body.categoryBitMask = CategoryBitmask.Water.rawValue
        body.collisionBitMask = 0
        body.contactTestBitMask = CategoryBitmask.Power.rawValue
        
        return body
    }
    
    private func createLavaPhysics() -> SKPhysicsBody {
        let splashTiles = findTilesWithUserData(named: "flicker")
        for (row, column) in splashTiles {
            let position = self.centerOfTile(atColumn: column, row: row)
            if let flickers = SKEmitterNode(fileNamed: "Flicker") {
                flickers.name = "Flicker"
                flickers.zPosition = 1
                flickers.position = position
                self.addChild(flickers)
            }
        }
        
        let body = getPhysicsBodyFrom(userData: "lava")
        body.affectedByGravity = false
        body.isDynamic = true
        body.mass = CGFloat(Int.max)
        body.allowsRotation = false
        body.pinned = true
        body.restitution = 0
        body.categoryBitMask = CategoryBitmask.Water.rawValue
        body.collisionBitMask = 0
        body.contactTestBitMask = CategoryBitmask.Power.rawValue
        
        return body
    }
    
    func freezeWater(atPosition position: CGPoint) {
        let localPosition = CGPoint(x: (position.x - self.position.x) / 2, y: (position.y - self.position.y) / 2)
        let row = self.tileRowIndex(fromPosition: localPosition)
        let column = self.tileColumnIndex(fromPosition: localPosition)
        
        if self.tileDefinition(atColumn: column, row: row)?.userData?["water"] == nil && self.tileDefinition(atColumn: column, row: row)?.userData?["lava"] == nil {
            return
        }
        
        var particleName = ""
        var textureName = ""
        if self.tileSet.name == "Grass" {
            particleName = "Splash"
            textureName = "Ice"
        } else if self.tileSet.name == "Volcano" {
            particleName = "Flicker"
            textureName = "Obsidian"
        }
        
        enumerateChildNodes(withName: particleName) {
            (node, _) in
            if node.position == self.centerOfTile(atColumn: column, row: row) {
                node.removeFromParent()
            }
        }
        
        let node = SKSpriteNode(texture: SKTexture(imageNamed: textureName) , size: self.tileSize)
        node.texture?.filteringMode = .nearest
        node.name = textureName
        node.position = self.centerOfTile(atColumn: column, row: row)
        node.zPosition = 1
        let body = SKPhysicsBody(rectangleOf: self.tileSize)
        body.affectedByGravity = false
        body.isDynamic = true
        body.mass = CGFloat(Int.max)
        body.allowsRotation = false
        body.pinned = true
        body.restitution = 0
        body.categoryBitMask = CategoryBitmask.Ground.rawValue
        body.collisionBitMask = CategoryBitmask.Player.rawValue + CategoryBitmask.Enemy.rawValue + CategoryBitmask.Power.rawValue
        body.contactTestBitMask = 0
        node.physicsBody = body
        
        addChild(node)
    }
    
    func initializePhysicsBody() {
        let physicsNode = SKNode()
        physicsNode.name = "Ground Physics"
        physicsNode.physicsBody = createPhysicsBody()
        addChild(physicsNode)
        
        if self.tileSet.name == "Grass" {
            let waterNode = SKNode()
            waterNode.name = "Liquid Physics"
            waterNode.physicsBody = createWaterPhysics()
            addChild(waterNode)
        } else if self.tileSet.name == "Volcano" {
            let lavaNode = SKNode()
            lavaNode.name = "Liquid Physics"
            lavaNode.physicsBody = createLavaPhysics()
            addChild(lavaNode)
        }
    }
    
}

func getUnlockedPowers() -> [Bool] {
    //guard let powers = defaults.object(forKey: "inventory") as? [Bool] else { fatalError("Couldn't get unlocked levels") }
    return [true, true, false]
}

func unlock(power: Int) {
    var powers = getUnlockedPowers()
    powers[power] = true
    defaults.set(powers, forKey: "inventory")
}

func getUnlockedLevels() -> [Bool] {
    //guard let levels = defaults.object(forKey: "unlockedLevels") as? [Bool] else { fatalError("Couldn't get unlocked levels") }
    return [true, true, true, true]
}

func unlock(level: Int) {
    var levels = getUnlockedLevels()
    levels[level] = true
    defaults.set(levels, forKey: "unlockedLevels")
}
