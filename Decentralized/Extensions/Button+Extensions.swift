//
//  Button+Extensions.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/26.
//

import Foundation
import SwiftUI

extension Button {
    func primary() -> some View {
        self.buttonStyle(BorderedProminentButtonStyle())
            .controlSize(.large)
    }
    
   
}
