//
//  Item.swift
//  PawPin
//
//  Created by almasah on 24/11/1447 AH.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
