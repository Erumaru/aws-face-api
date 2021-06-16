//
//  AppDelegate.swift
//  AWSFaceAPI
//
//  Created by Abzal Toremuratuly on 21.04.2021.
//

import UIKit
import AWSCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: .EUCentral1,
            identityPoolId: "eu-central-1:33b0b35e-d696-41fb-85a5-ae873bf1c7de")
        let configuration = AWSServiceConfiguration(
            region: .EUCentral1,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        return true
    }
}

