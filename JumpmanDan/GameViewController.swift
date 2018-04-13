//
//  GameViewController.swift
//  JumpmanDan
//
//  Created by Thomas Lauerman on 4/20/17.
//  Copyright © 2017 Thomas Lauerman. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if defaults.bool(forKey: "runBefore") == true {
            defaults.set(true, forKey: "runBefore")
            defaults.set(false, forKey: "debug")
            defaults.set(true, forKey: "muteMusic")
            defaults.set([true, true, false], forKey: "inventory")
            defaults.set(0, forKey: "selectedItem")
            defaults.set([true, true, true, false], forKey: "unlockedLevels")
            defaults.set(1, forKey: "lastSelectedLevel")
        }
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "TitleScreen") {                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            
            if defaults.bool(forKey: "debug") {
                view.showsFPS = true
                view.showsNodeCount = true
                view.showsPhysics = true
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
