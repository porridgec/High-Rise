/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SceneKit
import SpriteKit

class ViewController: UIViewController {
  @IBOutlet weak var scnView: SCNView!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var perfectMatchLabel: UILabel!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var sLabel: UILabel!
  @IBOutlet weak var pLabel: UILabel!
  @IBOutlet var labels: [UILabel]!
  
  var scnScene: SCNScene!
  
  var direction = true
  var height = 0
  
  var previousSize = SCNVector3.init(x: 0.5, y: 0.2, z: 0.5)
  var previousPosition = SCNVector3.init(x: 0, y: 0.1, z: 0)
  var currentSize = SCNVector3.init(x: 0.5, y: 0.2, z: 0.5)
  var currentPosition = SCNVector3Zero
  
  var offset = SCNVector3Zero
  var absoluteOffset = SCNVector3Zero
  var newSize = SCNVector3Zero
  
  var perfectMatches = 0
  
  var sounds = [String: SCNAudioSource]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loadSound(name: "GameOver", path: "HighRise.scnassets/Audio/GameOver.wav")
    loadSound(name: "PerfectFit", path: "HighRise.scnassets/Audio/PerfectFit.wav")
    loadSound(name: "SliceBlock", path: "HighRise.scnassets/Audio/SliceBlock.wav")
  
    scnScene = SCNScene(named: "HighRise.scnassets/Scenes/GameScene.scn")
    scnView.scene = scnScene
    scnView.isPlaying = true
    scnView.delegate = self
    
    
    [sLabel, scoreLabel, pLabel, perfectMatchLabel].forEach{ $0?.isHidden = true }
    
//    let blockNode = SCNNode.init(geometry: SCNBox.init(width: 0.5, height: 0.2, length: 0.5, chamferRadius: 0))
//    blockNode.position.z = -0.75
//    blockNode.position.y = 0.1
//    blockNode.name = "Block\(height)"
//
//    blockNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//    scnScene.rootNode.addChildNode(blockNode)
  }
  
  func loadSound(name: String, path: String) {
    guard let sound = SCNAudioSource.init(fileNamed: path) else { return }
    sound.isPositional = false
    sound.volume = 1
    sound.load()
    sounds[name] = sound
  }
  
  func playSound(sound: String, node: SCNNode) {
    node.runAction(SCNAction.playAudio(sounds[sound]!, waitForCompletion: false))
  }
  
  @IBAction func playGame(_ sender: Any) {
    playButton.isHidden = true
    [sLabel, scoreLabel, pLabel, perfectMatchLabel].forEach{ $0?.isHidden = false }
    let gameScene = SCNScene(named: "HighRise.scnassets/Scenes/GameScene.scn")!
    let transition = SKTransition.fade(withDuration: 1.0)
    scnScene = gameScene
    let mainCamera = scnScene.rootNode.childNode(withName: "Main Camera", recursively: false)!
    scnView.present(scnScene, with: transition, incomingPointOfView: mainCamera, completionHandler: nil)
    
    height = 0
    scoreLabel.text = "\(height)"
    
    direction = true
    perfectMatches = 0
    
    previousSize = SCNVector3(0.5, 0.2, 0.5)
    previousPosition = SCNVector3(0, 0.1, 0)
    
    currentSize = SCNVector3(0.5, 0.2, 0.5)
    currentPosition = SCNVector3Zero
    
    let blockNode = SCNNode.init(geometry: SCNBox.init(width: 0.5, height: 0.2, length: 0.5, chamferRadius: 0))
    blockNode.position.z = -0.75
    blockNode.position.y = 0.1
    blockNode.name = "Block\(height)"
    
    blockNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    scnScene.rootNode.addChildNode(blockNode)
  }
  
  func gameOver() {
    shakeNode(scnScene.rootNode.childNode(
      withName: "Main Camera", recursively: false)!)
    [sLabel, scoreLabel, pLabel, perfectMatchLabel].forEach{ $0?.isHidden = true }
    let mainCamera = scnScene.rootNode.childNode(
      withName: "Main Camera", recursively: false)!
    
    let fullAction = SCNAction.customAction(duration: 0.3) { _,_ in
      let moveAction = SCNAction.move(to: SCNVector3Make(mainCamera.position.x,
                                                         mainCamera.position.y * (3/4), mainCamera.position.z), duration: 0.3)
      mainCamera.runAction(moveAction)
      if self.height <= 15 {
        mainCamera.camera?.orthographicScale = 1
      } else {
        mainCamera.camera?.orthographicScale = Double(Float(self.height/2) /
          mainCamera.position.y)
      }
    }
    
    mainCamera.runAction(fullAction)
    playButton.isHidden = false
  }
  
  @IBAction func handleTap(_ sender: Any) {
    if let currentBoxNode = scnScene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
      currentPosition = currentBoxNode.presentation.position
      let boundsMin = currentBoxNode.boundingBox.min
      let boundsMax = currentBoxNode.boundingBox.max
      currentSize = boundsMax - boundsMin
      
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
      
      if height % 2 == 0 && newSize.z <= 0 {
        height += 1
        currentBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                    shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
        playSound(sound: "GameOver", node: currentBoxNode)
        gameOver()
        return
      } else if height % 2 != 0 && newSize.x <= 0 {
        height += 1
        currentBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                    shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
        playSound(sound: "GameOver", node: currentBoxNode)
        gameOver()
        return
      }
      
      checkPerfectMatch(currentBoxNode)
      
      currentBoxNode.geometry = SCNBox.init(width: CGFloat(newSize.x), height: 0.2, length: CGFloat(newSize.z), chamferRadius: 0)
      currentBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
      currentBoxNode.position = SCNVector3Make(currentPosition.x + (offset.x / 2), currentPosition.y, currentPosition.z + (offset.z / 2))
      currentBoxNode.physicsBody = SCNPhysicsBody.init(type: .static, shape: SCNPhysicsShape.init(geometry: currentBoxNode.geometry!, options: nil))
      
      addNewBlock(currentBoxNode)
      addBrokenBlock(currentBoxNode)
      
      if height > 3 {
        let moveAction = SCNAction.move(by: SCNVector3.init(0, 0.2, 0), duration: 0.2)
        let mainCamera = scnScene.rootNode.childNode(withName: "Main Camera", recursively: false)
        mainCamera?.runAction(moveAction)
      }
      
      scoreLabel.text = "\(height + 1)"
      
      previousSize = SCNVector3Make(newSize.x, 0.2, newSize.z)
      previousPosition = currentBoxNode.position
      height += 1
    }
  }
  
  func addNewBlock(_ currentBoxNode: SCNNode) {
    let newBoxNode = SCNNode.init(geometry: currentBoxNode.geometry!)
    newBoxNode.position = SCNVector3Make(currentBoxNode.position.x, currentBoxNode.position.y + 0.2, currentBoxNode.position.z)
    newBoxNode.name = "Block\(height + 1)"
    newBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
    
    if height % 2 == 0 {
      newBoxNode.position.x -= 0.75
    } else {
      newBoxNode.position.z -= 0.75
    }
    playSound(sound: "SliceBlock", node: currentBoxNode)
    scnScene.rootNode.addChildNode(newBoxNode)
  }
  
  func addBrokenBlock(_ currentBoxNode: SCNNode) {
    let brokenBoxNode = SCNNode()
    brokenBoxNode.name = "Broken\(height)"
    
    if height % 2 == 0 && absoluteOffset.z > 0 {
      brokenBoxNode.geometry = SCNBox.init(width: CGFloat(currentSize.x), height: 0.2, length: CGFloat(absoluteOffset.z), chamferRadius: 0)
      
      if offset.z > 0 {
        brokenBoxNode.position.z = currentBoxNode.position.z - (offset.z / 2) - ((currentSize - offset).z / 2)
      } else {
        brokenBoxNode.position.z = currentBoxNode.position.z - (offset.z / 2) + ((currentSize + offset).z / 2)
      }
      brokenBoxNode.position.x = currentBoxNode.position.x
      brokenBoxNode.position.y = currentPosition.y
      
      brokenBoxNode.physicsBody = SCNPhysicsBody.init(type: .dynamic, shape: SCNPhysicsShape.init(geometry: brokenBoxNode.geometry!, options: nil))
      brokenBoxNode.geometry!.firstMaterial?.diffuse.contents = UIColor.red
      scnScene.rootNode.addChildNode(brokenBoxNode)
    } else if height % 2 != 0 && absoluteOffset.x > 0 {
      brokenBoxNode.geometry = SCNBox.init(width: CGFloat(absoluteOffset.x), height: 0.2, length: CGFloat(currentSize.z), chamferRadius: 0)
      
      if offset.x > 0 {
        brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) -
          ((currentSize - offset).x/2)
      } else {
        brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) +
          ((currentSize + offset).x/2)
      }
      brokenBoxNode.position.y = currentPosition.y
      brokenBoxNode.position.z = currentBoxNode.position.z
      
      brokenBoxNode.physicsBody = SCNPhysicsBody.init(type: .dynamic, shape: SCNPhysicsShape.init(geometry: brokenBoxNode.geometry!, options: nil))
      brokenBoxNode.geometry!.firstMaterial?.diffuse.contents = UIColor.red
      scnScene.rootNode.addChildNode(brokenBoxNode)
    }
  }
  
  func checkPerfectMatch(_ currentBoxNode: SCNNode) {
    if height % 2 == 0 && absoluteOffset.z <= 0.03 {
      playSound(sound: "PerfectFit", node: currentBoxNode)
      currentBoxNode.position.z = previousPosition.z
      currentPosition.z = previousPosition.z
      perfectMatches += 1
      if perfectMatches >= 7 && currentSize.z < 1 {
        newSize.z += 0.05
      }
      perfectMatchLabel.text = "\(perfectMatches)"
      
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
    } else if height % 2 != 0 && absoluteOffset.x <= 0.03 {
      playSound(sound: "PerfectFit", node: currentBoxNode)
      currentBoxNode.position.x = previousPosition.x
      currentPosition.x = previousPosition.x
      perfectMatches += 1
      if perfectMatches >= 7 && currentSize.x < 1 {
        newSize.x += 0.05
      }
      perfectMatchLabel.text = "\(perfectMatches)"
      
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
    } else {
      perfectMatches = 0
      perfectMatchLabel.text = "\(perfectMatches)"
    }
  }
  
  func shakeNode(_ node:SCNNode) {
    let left = SCNAction.move(by: SCNVector3(x: -0.2, y: 0.0, z: 0.0), duration: 0.05)
    let right = SCNAction.move(by: SCNVector3(x: 0.2, y: 0.0, z: 0.0), duration: 0.05)
    let up = SCNAction.move(by: SCNVector3(x: 0.0, y: 0.2, z: 0.0), duration: 0.05)
    let down = SCNAction.move(by: SCNVector3(x: 0.0, y: -0.2, z: 0.0), duration: 0.05)
    
    node.runAction(SCNAction.sequence([
      left, up, down, right, left, right, down, up, right, down, left, up,
      left, up, down, right, left, right, down, up, right, down, left, up]))
  }
  
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  
  
}

extension ViewController: SCNSceneRendererDelegate {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    for node in scnScene.rootNode.childNodes {
      if node.presentation.position.y <= -20 {
        node.removeFromParentNode()
      }
    }
    if let currentNode = scnScene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
      if height % 2 == 0 {
        if currentNode.position.z >= 0.75 {
          direction = false
        } else if currentNode.position.z <= -0.75 {
          direction = true
        }
        
        switch direction {
        case true:
          currentNode.position.z += 0.01
        case false:
          currentNode.position.z -= 0.01
        }
      } else {
        if currentNode.position.x >= 0.75 {
          direction = false
        } else if currentNode.position.x <= -0.75 {
          direction = true
        }
        
        switch direction {
        case true:
          currentNode.position.x += 0.01
        case false:
          currentNode.position.x -= 0.01
        }
      }
    }
  }
}
