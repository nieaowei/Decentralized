//
//  Button+Extensions.swift
//  Decentralize
//
//  Created by Nekilc on 2024/5/26.
//

import Foundation
import SwiftUI

extension Button {
    @MainActor func primary() -> some View {
        self.buttonStyle(.glass)
            .controlSize(.large)
    }
   
    func secondary() -> some View {
        self.buttonStyle(BorderedButtonStyle())
            .controlSize(.large)
    }
}


extension NavigationLink{
    func primary() -> some View {
        self.buttonStyle(BorderedProminentButtonStyle())
            .controlSize(.large)
    }
}
