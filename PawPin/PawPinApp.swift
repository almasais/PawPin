//
//  PawPinApp.swift
//  PawPin
//
//  Created by almasah on 24/11/1447 AH.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct PawPinApp: App {
    var body: some Scene {
        WindowGroup {
            OTPVerificationView() // تأكدي إن المكتوب هنا AuthView مو ContentView
        }
    }
}
      
