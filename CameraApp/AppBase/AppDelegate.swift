//
//  AppDelegate.swift
//  CameraApp
//
//  Created by Dheeraj Kumar Sharma on 04/06/22.
//

import UIKit
import AVKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var camera: MetalCamera!
    var metalView: MetalView!
    var videoWriter: MetalVideoWriter!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func setupCamera(){
        if(self.camera == nil){
            // Added this code to maintain camera session throughout application to avoid black screen between camera transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.camera = MetalCamera(sessionPreset: .hd1920x1080)
                self.camera.canTakePhoto = true
                let  filePath = NSTemporaryDirectory() + "demo.mp4"
                let url = URL(fileURLWithPath: filePath)
                self.videoWriter = MetalVideoWriter(url: url, frameSize: MetalIntSize(width: 1080, height: 1920))
                self.camera.audioConsumer = self.videoWriter
                self.camera.add(consumer: self.videoWriter)
                self.camera.startSession()
            }
        }
    }


}

