//
//  SceneDelegate.swift
//  Pirate
//
//  Created by hyperorchid on 2020/2/15.
//  Copyright © 2020 hyperorchid. All rights reserved.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        
        
//        var timer:Timer?
        var window: UIWindow?

        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
                // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
                // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
                // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
                guard let _ = (scene as? UIWindowScene) else { return }
        }

        func sceneDidDisconnect(_ scene: UIScene) {
                // Called as the scene is being released by the system.
                // This occurs shortly after the scene enters the background, or when its session is discarded.
                // Release any resources associated with this scene that can be re-created the next time the scene connects.
                // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
        }

        func sceneDidBecomeActive(_ scene: UIScene) {
//                DataSyncer.EthVersionCheck()
//                DispatchQueue.main.async {
//                        NSLog("============>timer init--->")
//                        self.timer = Timer.scheduledTimer(withTimeInterval:
//                        AppDelegate.SyncTimer, repeats: true) {
//                                (time) in
//                                DataSyncer.EthVersionCheck()
//                }}
        }

        func sceneWillResignActive(_ scene: UIScene) {
                // Called when the scene will move from an active state to an inactive state.
                // This may occur due to temporary interruptions (ex. an incoming phone call).
        }
        func sceneWillEnterForeground(_ scene: UIScene) {
                // Called as the scene transitions from the background to the foreground.
                // Use this method to undo the changes made on entering the background.
        }

        func sceneDidEnterBackground(_ scene: UIScene) {
                NSLog("============>timer invalidate--->")
//                self.timer?.invalidate()
                let context = DataShareManager.privateQueueContext()
                DataShareManager.saveContext(context)
                DataShareManager.syncAllContext(context)
        }

}

