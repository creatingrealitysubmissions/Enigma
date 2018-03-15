//
//  ViewController.swift
//  AR Puzzle
//
//  Created by Siyu Lei on 3/13/18.
//  Copyright © 2018 Siyu Lei. All rights reserved.
//

import UIKit
import ARKit

enum BitMaskCategory: Int {
    case bullet = 8
    case target = 9
}
class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    var isFirstVisted: Bool = true

    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    //added
    var power: Float = 50
    var Target: SCNNode?
    
    let configuration = ARWorldTrackingConfiguration()
    var portalAdded: Bool = false
    var node_on_hand = SCNNode()
    var pickOrNot: Bool = false
    var location:SCNVector3 = SCNVector3(0,0,0)
    var currentPositionOfCamera:SCNVector3 = SCNVector3(0,0,0)
    var node_name_picked = ""
    var home_position = SCNVector3(0,0,0)
    var isGameStarted:Bool = false
    var isMission1Done:Bool = false
    var isMission2Done:Bool = false
    
    var isShoot:Bool = false
    @IBOutlet weak var aim: UILabel!
    @IBOutlet weak var dropDownButton: UIButton!
    @IBOutlet weak var pickUpButton: UIButton!
    @IBAction func pickUp(_ sender: Any) {
        if isGameStarted {
            self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                if (node.name == "box" || node.name == "Book" || node.name == "box_1" || node.name == "box_2" || node.name == "cup") && !pickOrNot {
                    let transform = node.transform
                    var node_location = SCNVector3(transform.m41, transform.m42, transform.m43)
                    if measureDis(left: node_location, right: currentPositionOfCamera,distance:0.2) {
                        if let temp = node.name{
                            node_name_picked = temp
                            print(node_name_picked)
                        }
                        node.removeFromParentNode()
                        pickOrNot = true
                    }
                }
                
            })
        }
    }
    @IBAction func dropOff(_ sender: Any) {
        if pickOrNot {
            node_on_hand.removeFromParentNode()
            pickOrNot = false
            if node_name_picked == "box" || node_name_picked == "box_1" || node_name_picked == "box_2"{
                let node_down = SCNNode()
                node_down.name = node_name_picked
                node_down.geometry = SCNBox(width:0.2,height:0.2,length:0.2,chamferRadius:0)
                node_down.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                node_down.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.addChildNode(node_down)
            } else {
                let bookScene  = SCNScene(named:"art.scnassets/\(node_name_picked).scn")
                let node_down = (bookScene?.rootNode.childNode(withName:node_name_picked,recursively: false))!
                node_down.position = currentPositionOfCamera
                self.sceneView.scene.rootNode.addChildNode(node_down)
            }
            node_name_picked = ""
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.registerGestureRecognizers()
        
        //addTarget()
        self.sceneView.scene.physicsWorld.contactDelegate = self
        
        // Do any additional setup after loading the view, typically from a nib.
//        let test = SCNScene(named: "art.scnassets/cup.scn")
//        let testNode = test!.rootNode.childNode(withName: "cup", recursively: true)!
//        testNode.position = SCNVector3(0,1,-2)
//        sceneView.scene.rootNode.addChildNode(testNode)
    }
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        //let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handlePress))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        //self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    @objc func handleTap(sender: UITapGestureRecognizer) {
        //        addBullet()
        if portalAdded == false {
            return
        }
        if isShoot {
            addBullet()
        } else {
            let sceneView = sender.view as! ARSCNView
            let holdLocation = sender.location(in: sceneView)
            let hitTest = sceneView.hitTest(holdLocation)
            
            if !hitTest.isEmpty {
                let result = hitTest.first!
                addNode(in1 : result)
            }
        }
    }
    
    @objc func handlePress(sender: UILongPressGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        if !hitTestResult.isEmpty {
            //let node = result.node
            if sender.state == .began {
                //
            } else if sender.state == .ended {
                self.addPortal(hitTestResult: hitTestResult.first!)
            }
        }
    }
    //    @objc func handleTap(sender: UITapGestureRecognizer) {
//        guard let sceneView = sender.view as? ARSCNView else {return}
//        let touchLocation = sender.location(in: sceneView)
//        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
//        if !hitTestResult.isEmpty {
//            self.addPortal(hitTestResult: hitTestResult.first!)
//        }
//    }
    
//    @objc func handlePress(sender: UILongPressGestureRecognizer) {
//        if portalAdded == false {
//            return
//        }
//        let sceneView = sender.view as! ARSCNView
//        let holdLocation = sender.location(in: sceneView)
//        let hitTest = sceneView.hitTest(holdLocation)
////        print(type(of: hitTest))
//
//        if !hitTest.isEmpty {
//            let result = hitTest.first!
//            //let node = result.node
//            if sender.state == .began {
////                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
////                let forever = SCNAction.repeatForever(rotation)
////                result.node.runAction(forever)
//            } else if sender.state == .ended {
////                result.node.removeAllActions()
////                node.removeFromParentNode()
//                addNode(in1 : result)
//            }
////            if node.name == "Book" {
////                do something
////            }
////            if node.name == "cup" {
////                let portalNode = sceneView.scene.rootNode.childNode(withName: "Portal", recursively: true)
////                let transform = portalNode!.transform
////                let location = SCNVector3(transform.m41, transform.m42, transform.m43)
////                print(location)
////                if sender.state == .began {
////                    let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
////                    let forever = SCNAction.repeatForever(rotation)
////                    result.node.runAction(forever)
////                } else if sender.state == .ended {
////                    result.node.removeAllActions()
////                    node.removeFromParentNode()
////                }
////
////            }
//        }
//    }
    
////// added by Eric for adding Node and connect the storyline
    func addNode(in1: SCNHitTestResult){
        let input = in1
        let results = input
        let node = results.node
        let portalNode = sceneView.scene.rootNode.childNode(withName: "Portal", recursively: true)
        let transform = portalNode!.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let home_x = location.x
        let home_y = location.y
        let home_z = location.z
        if let name = node.name {
            if name == "jelly" {
                node.removeFromParentNode()
                let bookScene  = SCNScene(named:"art.scnassets/Book.scn")
                let bookNode = bookScene?.rootNode.childNode(withName:"Book",recursively: false)
                bookNode?.position = SCNVector3(0,0,-0.3)
                sceneView.scene.rootNode.addChildNode(bookNode!)
            } else if name == "Book"{
                isGameStarted = true
                node.removeFromParentNode()
                let cupScene = SCNScene(named: "art.scnassets/cup.scn")
                let cupNode = cupScene!.rootNode.childNode(withName: "cup", recursively: false)!
                cupNode.position = SCNVector3(home_x-1.5,home_y,home_z-3.5)
                sceneView.scene.rootNode.addChildNode(cupNode)
//                let bookScene  = SCNScene(named:"art.scnassets/jelly.scn")
//                let bookNode = bookScene?.rootNode.childNode(withName:"jelly",recursively: false)
//                bookNode?.position = SCNVector3(home_x-1.5,home_y+1,home_z-3.5)
//                sceneView.scene.rootNode.addChildNode(bookNode!)
                closeDoor()
            }else if name == "gun" && isMission2Done{
                self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                    if node.name == "gun" {
                        node.removeFromParentNode()
                    }
                })
                self.planeDetected.text = "Please shoot the vase"
                isShoot = true;
                pickUpButton.isHidden = true
                dropDownButton.isHidden = true
                aim.isHidden = false
                addVase(x:home_position.x-1.5,y:home_position.y+1.5,z:home_position.z-1.5)
            } else if name == "cup" {
                let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: node))
                //body.isAffectedByGravity = true
                node.physicsBody = body
                body.restitution = 0.5
            } else if name == "key" {
                self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                    if node.name == "door" {
                        node.isHidden = true;
                    }
                }
                self.planeDetected.text = "Congratulation, back to real world"
                node.removeFromParentNode()
                
            }
//            else if name == "box" {
//                if pickOrNot == false{
//                    node_name_picked = "box"
//                    node.removeFromParentNode()
//                    pickOrNot = true
//                } else { // put box down
//                    node_name_picked = ""
//                    let down_postion = node.position
//                    node.removeFromParentNode()
//                    pickOrNot = false
//                    let node_down = SCNNode()
//                    node_down.name = "box"
//                    node_down.geometry = SCNBox(width:0.2,height:0.2,length:0.2,chamferRadius:0)
//                    node_down.geometry?.firstMaterial?.diffuse.contents = UIColor.white
//                    node_down.position = down_postion
//                    self.sceneView.scene.rootNode.addChildNode(node_down)
//                }
//
//            }
        } else {
            print("nil")
        }
    }
    func closeDoor() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "door" {
                node.isHidden = false;
            }
        }
    }
    func addPortal(hitTestResult: ARHitTestResult) {
        if !portalAdded {
            portalAdded = true
            self.planeDetected.text = "Please tap the book"
            let portalScene = SCNScene(named: "art.scnassets/Portal.scn")
            let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
            let transform = hitTestResult.worldTransform
            let planeXposition = transform.columns.3.x
            let planeYposition = transform.columns.3.y
            let planeZposition = transform.columns.3.z
            portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition - 1)
            //added by Eric
            home_position = portalNode.position
            initial(basic_position: home_position)
            //above one line added to get home position
            self.sceneView.scene.rootNode.addChildNode(portalNode)
    //        self.addPlane(nodeName: "roof", portalNode: portalNode, imageName: "top")
    //        self.addPlane(nodeName: "floor", portalNode: portalNode, imageName: "bottom")
    //        self.addWalls(nodeName: "backWall", portalNode: portalNode, imageName: "back")
    //        self.addWalls(nodeName: "sideWallA", portalNode: portalNode, imageName: "sideA")
    //        self.addWalls(nodeName: "sideWallB", portalNode: portalNode, imageName: "sideB")
    //        self.addWalls(nodeName: "sideDoorA", portalNode: portalNode, imageName: "sideDoorA")
    //        self.addWalls(nodeName: "sideDoorB", portalNode: portalNode, imageName: "sideDoorB")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        if !portalAdded {
            DispatchQueue.main.async {
                self.planeDetected.text = "Please press the floor"
            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.planeDetected.text = "Continue focus on floor"
//            }
        }
    }
    //
    ///// added by Eric for picking up box and dropping off it
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
            guard let pointOfView = sceneView.pointOfView else {return}
            let transform = pointOfView.transform
            location = SCNVector3(transform.m41,transform.m42,transform.m43)
            let orientation = SCNVector3(-transform.m31,-transform.m32,-transform.m33)
            currentPositionOfCamera = addVector(left:orientation, right: location)
        //condition
            DispatchQueue.main.async {
                // added by Eric for adding a center point as helper point
                if !self.isShoot {
                    let pointer = SCNNode(geometry: SCNSphere(radius: 0.01))
                    pointer.name = "pointer"
                    pointer.position = self.currentPositionOfCamera
                    self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                        if node.name == "pointer" {
                            node.removeFromParentNode()
                        }
                    })
                    self.sceneView.scene.rootNode.addChildNode(pointer)
                    pointer.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    if self.isGameStarted{
                        if self.pickOrNot{
                            if self.node_name_picked == "box" || self.node_name_picked == "box_1" || self.node_name_picked == "box_2" {
                                self.node_on_hand.geometry = SCNBox(width:0.3,height:0.3,length:0.3,chamferRadius:0)
                                self.node_on_hand.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                                self.node_on_hand.position = self.currentPositionOfCamera
                            } else if self.node_name_picked != "" {
                                let bookScene  = SCNScene(named:"art.scnassets/\(self.node_name_picked).scn")
                                self.node_on_hand = (bookScene?.rootNode.childNode(withName:self.node_name_picked,recursively: false))!
                                self.node_on_hand.position = self.currentPositionOfCamera
                            }
                            
                            self.sceneView.scene.rootNode.enumerateChildNodes({(node,_) in
                                if node.name == self.node_name_picked{
                                    node.removeFromParentNode()
                                }
                            })
                            self.sceneView.scene.rootNode.addChildNode(self.node_on_hand)
                        } else {
                            if !self.isMission2Done && self.isMission1Done{
                                if self.checkmission2(){
                                    self.planeDetected.text = "Please find a gun around you"
                                    self.isMission2Done = true
                                }
                                else {
                                    self.planeDetected.text = "Please put cup on the desk"
                                }
                            }
                            if !self.isMission1Done{
                                print(self.checkheight())
                                if self.checkheight() {
                                    self.planeDetected.text = "Please move to next mission"
                                    self.isMission1Done = true
                                } else {
                                    self.planeDetected.text = "Move cubes in a vertical line"
                                }
                            }
                        }
                    }
                } else {
                    self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
                        if node.name == "pointer" {
                            node.removeFromParentNode()
                        }
                    })
                }
               
            }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        if !portalAdded {
            DispatchQueue.main.async {
                self.planeDetected.text = "Please long press the floor"
            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                self.planeDetected.text = "Continue focus on floor"
//            }
            
            
        }
    }
    
    
    func addWalls(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/\(imageName).png")
        child?.renderingOrder = 200
        if let mask = child?.childNode(withName: "mask", recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
    }
    
    
    func addPlane(nodeName: String, portalNode: SCNNode, imageName: String) {
        let child = portalNode.childNode(withName: nodeName, recursively: true)
        child?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Portal.scnassets/\(imageName).png")
        child?.renderingOrder = 200
    }
    func initial(basic_position: SCNVector3){
        // add box 1
        let node_box = SCNNode()
        node_box.name = "box"
        node_box.geometry = SCNBox(width:0.2,height:0.2,length:0.2,chamferRadius:0)
        node_box.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node_box.position = SCNVector3(basic_position.x+0.1, basic_position.y+0.1, basic_position.z - 0.1)
        self.sceneView.scene.rootNode.addChildNode(node_box)
        //add box 2
        let node_box_1 = SCNNode()
        node_box_1.name = "box_1"
        node_box_1.geometry = SCNBox(width:0.2,height:0.2,length:0.2,chamferRadius:0)
        node_box_1.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node_box_1.position = SCNVector3(basic_position.x+1, basic_position.y+0.1, basic_position.z - 0.4)
        self.sceneView.scene.rootNode.addChildNode(node_box_1)
        //add box 3
        let node_box_2 = SCNNode()
        node_box_2.name = "box_2"
        node_box_2.geometry = SCNBox(width:0.2,height:0.2,length:0.2,chamferRadius:0)
        node_box_2.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node_box_2.position = SCNVector3(basic_position.x-1, basic_position.y+0.1, basic_position.z - 2)
        self.sceneView.scene.rootNode.addChildNode(node_box_2)
        //add book
        let bookScene  = SCNScene(named:"art.scnassets/Book.scn")
        let bookNode = bookScene?.rootNode.childNode(withName:"Book",recursively: false)
        bookNode?.position = SCNVector3(basic_position.x,basic_position.y+1,basic_position.z-1.5)
        sceneView.scene.rootNode.addChildNode(bookNode!)
        //add desk
        let deskScene  = SCNScene(named:"art.scnassets/desk.scn")
        let deskNode = deskScene?.rootNode.childNode(withName:"desk",recursively: false)
        deskNode?.position = SCNVector3(basic_position.x+1,basic_position.y+0.5,basic_position.z-2)
        sceneView.scene.rootNode.addChildNode(deskNode!)
        //add gun
        let gunScene  = SCNScene(named:"art.scnassets/gun.scn")
        let gunNode = gunScene?.rootNode.childNode(withName:"gun",recursively: false)
        gunNode?.position = SCNVector3(basic_position.x+1,basic_position.y+0.2,basic_position.z-2)
        sceneView.scene.rootNode.addChildNode(gunNode!)
        
    }
    func randomNumbers(firstNum: CGFloat, secondNum: CGFloat)-> CGFloat{
        return CGFloat(arc4random())/CGFloat(UINT32_MAX)*abs(firstNum-secondNum)+min(firstNum,secondNum)
    }
    func addVector(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    func addBullet() {
        guard let pointOfView = sceneView.pointOfView else {return}
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let position = orientation + location
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.1))
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        bullet.position = position
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: bullet, options: nil))
        body.isAffectedByGravity = false
        bullet.physicsBody = body
        bullet.physicsBody?.applyForce(SCNVector3(orientation.x*power, orientation.y*power, orientation.z*power), asImpulse: true)
        bullet.physicsBody?.categoryBitMask = BitMaskCategory.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BitMaskCategory.target.rawValue
        self.sceneView.scene.rootNode.addChildNode(bullet)
        bullet.runAction(
            SCNAction.sequence([SCNAction.wait(duration: 2.0),
                                SCNAction.removeFromParentNode()])
        )
    }
    
    func addTarget() {
        self.addVase(x: 1, y: 1, z: -0.5)
        self.addVase(x: 0, y: 1, z: -0.5)
        //        self.addEgg(x: 0, y: 1, z: 0.5)
        //        self.addEgg(x: -1, y: 1, z: 0.5)
    }
    
    func addVase(x: Float, y: Float, z: Float) {
        let vaseScene = SCNScene(named: "art.scnassets/vase.scn")
        let vaseNode = (vaseScene?.rootNode.childNode(withName: "vase", recursively: false))!
        vaseNode.position = SCNVector3(x,y,z)
        vaseNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: vaseNode, options: nil))
        vaseNode.physicsBody?.categoryBitMask = BitMaskCategory.target.rawValue
        vaseNode.physicsBody?.contactTestBitMask = BitMaskCategory.bullet.rawValue
        self.sceneView.scene.rootNode.addChildNode(vaseNode)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        DispatchQueue.main.async {
            if self.isShoot {
                let nodeA = contact.nodeA
                let nodeB = contact.nodeB
                self.Target = nil
                if nodeA.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
                    self.Target = nodeA
                } else if nodeB.physicsBody?.categoryBitMask == BitMaskCategory.target.rawValue {
                    self.Target = nodeB
                }
                if self.Target != nil {
                    let confetti = SCNParticleSystem(named: "art.scnassets/Fire.scnp", inDirectory: nil)
                    confetti?.loops = false
                    confetti?.particleLifeSpan = 4
                    confetti?.emitterShape = self.Target?.geometry
                    let confettiNode = SCNNode()
                    confettiNode.addParticleSystem(confetti!)
                    confettiNode.position = contact.contactPoint
                    self.sceneView.scene.rootNode.addChildNode(confettiNode)
                    self.Target?.removeFromParentNode()
                    DispatchQueue.main.async {
                        self.isShoot = false
                        self.aim.isHidden = true
                        self.pickUpButton.isHidden = false
                        self.dropDownButton.isHidden = false
                        
                        let keyScene = SCNScene(named: "art.scnassets/Key.scn")
                        let keyNode = keyScene!.rootNode.childNode(withName: "key", recursively: false)!
                        keyNode.position = SCNVector3(self.home_position.x,self.home_position.y+1,self.home_position.z-0.3)
                        self.sceneView.scene.rootNode.addChildNode(keyNode)
                        self.planeDetected.text = "Please tap the key"
                    }
                }
            }
        }
    }
    func checkheight()->Bool{
        var flag: Bool = false
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            if (node.name == "box" || node.name == "box_1" || node.name == "box_2") && !pickOrNot {
                let transform = node.transform
                var node_location = SCNVector3(transform.m41, transform.m42, transform.m43)
                if node_location.y > 0.5 + home_position.y{
                    flag = true
                }
            }
        })
         return flag
    }
    func checkmission2()->Bool{
        let node_cup = self.sceneView.scene.rootNode.childNode(withName:"cup",recursively: false)!
        let cup_transform = node_cup.transform
        var cup_location = SCNVector3(cup_transform.m41, cup_transform.m42, cup_transform.m43)
        let node_desk = self.sceneView.scene.rootNode.childNode(withName:"desk",recursively: false)!
        let desk_transform = node_desk.transform
        var desk_location = SCNVector3(desk_transform.m41, desk_transform.m42, desk_transform.m43)
        return measureDis(left: cup_location, right: desk_location, distance: 1.0)
    }
    func measureDis(left: SCNVector3, right: SCNVector3,distance: Float) -> Bool {
        let dis = (left.x - right.x)*(left.x - right.x)+(left.y - right.y)*(left.y - right.y)+(left.z - right.z)*(left.z - right.z)
        if dis.squareRoot() <= distance {
            return true
        } else {
            return false
        }
    }
}
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}


