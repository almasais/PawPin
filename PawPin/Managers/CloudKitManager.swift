//
//  CloudKitManager.swift
//  PawPin
//ذذذ
//  Created by lay on 24/11/1447 AH.
//

import Foundation
import CloudKit

class CloudKitManager {
    
    static let shared = CloudKitManager()
    
    private let database = CKContainer.default().publicCloudDatabase
    
    // SAVE POST
    func saveCat(name: String, description: String) {
        
        let record = CKRecord(recordType: "CatPost")
        
        record["name"] = name
        record["description"] = description
        
        database.save(record) { record, error in
            
            if let error = error {
                print("ERROR SAVING:", error.localizedDescription)
            } else {
                print("SUCCESS")
            }
        }
    }
}
