//
//  PreviewContainer.swift
//  BTCt
//
//  Created by Nekilc on 2024/6/6.
//

import Foundation
import SwiftData
import SwiftUI

let preivewContainer: ModelContainer = {
    do {
        let con = try ModelContainer(for: Contact.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return con
    } catch {
        fatalError("error")
    }
}()
