//
//  ViewController.swift
//  ARBlogDemo
//
//  Created by Yudiz Solutions on 25/05/18.
//  Copyright © 2018 Yudiz Solutions. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var infoLabel: UILabel!
    var currentAngleY: Float = 0.0
    var object: SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)

        
        let scene = SCNScene()
        sceneView.scene = scene

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
//        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        infoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        infoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        infoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
     func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: - Gesture recognizer
extension ViewController: UIGestureRecognizerDelegate{
    
    @objc
    func didTap(_ gesture: UIPanGestureRecognizer) {
        guard let _ = object else { return }

        let tapLocation = gesture.location(in: sceneView)
        let results = sceneView.hitTest(tapLocation, types: .featurePoint)
        
        if let result = results.first {
            let translation = result.worldTransform.translation
            object.position = SCNVector3Make(translation.x, translation.y, translation.z)
            sceneView.scene.rootNode.addChildNode(object)
        }
    }
    
    @objc
    func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = object else { return }
        var originalScale = object?.scale
        
        switch gesture.state {
        case .began:
            originalScale = object?.scale
            gesture.scale = CGFloat((object?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.3{
                newScale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
            }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            object?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }
            if gesture.scale < 0.3{
                newScale = SCNVector3(x: 0.3, y: 0.3, z: 0.3)
            }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            object?.scale = newScale
            gesture.scale = CGFloat((object?.scale.x)!)
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
    
    @objc
    func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = object else { return }
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        
        newAngleY += currentAngleY
        object?.eulerAngles.y = newAngleY
        
        if gesture.state == .ended{
            currentAngleY = newAngleY
        }
    }
   

}

// MARK: - ARSCNView delegate
extension ViewController: ARSCNViewDelegate{
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.infoLabel.text = "Surface Detected."
        }
        
        let shoesScene = SCNScene(named: "Shoes_V4.dae", inDirectory: "Model.scnassets")
        object = shoesScene?.rootNode.childNode(withName: "group1", recursively: true)
        object.simdPosition = float3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        sceneView.scene.rootNode.addChildNode(object)
        node.addChildNode(object)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .normal :
            infoLabel.text = "Move the device to detect horizontal surfaces."

        case .notAvailable:
            infoLabel.text = "Tracking not available."
            
        case .limited(.excessiveMotion):
            infoLabel.text = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            infoLabel.text = "Tracking limited - Point the device at an area with visible surface detail."
            
        case .limited(.initializing):
            infoLabel.text = "Initializing AR session."
            
        default:
            infoLabel.text = ""
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Called when any node has been removed from sceneview
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Called when any node has been updated with data from anchor
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
