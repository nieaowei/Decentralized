//
//  Contact.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/31.
//

import Foundation
import SwiftData

@Model
class Contact {
    @Attribute(.unique) var addr: String
    var name: String = ""
    
    init(addr: String, name: String) {
        self.addr = addr
        self.name = name
    }
}
