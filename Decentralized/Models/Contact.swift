//
//  Contact.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/31.
//

import Foundation
import SwiftData

@Model
class Contact: Identifiable {
    @Attribute(.unique)
    var id: String

    @Attribute(.unique)
    var addr: String

    var name: String = ""

    init(addr: String, name: String) {
        self.id = addr
        self.addr = addr
        self.name = name
    }
}
