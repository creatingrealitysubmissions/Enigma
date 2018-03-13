//
//  ViewController.swift
//  AR Puzzle
//
//  Created by Siyu Lei on 3/13/18.
//  Copyright © 2018 Siyu Lei. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var planeDetected: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var portalAdded: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.delegate = self
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
//        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.registerGestureRecognizers()
        
        // Do any additional setup after loading the view, typically from a nib.
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
        guard let sceneView = sender.view as? ARSCNView else {return}
        let touchLocation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResult.isEmpty {
            self.addPortal(hitTestResult: hitTestResult.first!)
        }
    }
    
    @objc func handlePress(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty {
            let result = hitTest.first!
            let node = result.node
            print (node.name)
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)
            } else if sender.state == .ended {
                result.node.removeAllActions()
                node.removeFromParentNode()
            }
        }
    }
    
    func addPortal(hitTestResult: ARHitTestResult) {
        if portalAdded {
            portalAdded = false
            let portalScene = SCNScene(named: "art.scnassets/Portal.scn")
            let portalNode = portalScene!.rootNode.childNode(withName: "Portal", recursively: false)!
            let transform = hitTestResult.worldTransform
            let planeXposition = transform.columns.3.x
            let planeYposition = transform.columns.3.y
            let planeZposition = transform.columns.3.z
            portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition)
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
        DispatchQueue.main.async {
            self.planeDetected.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetected.isHidden = true
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
    
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}

