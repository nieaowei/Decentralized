//
//  Item.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/10.
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
