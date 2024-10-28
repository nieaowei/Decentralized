//
//  Bundle+Extensions.swift
//  Decentralize
//
//

import Foundation

extension Bundle {
    var displayName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? Bundle.main
            .bundleIdentifier ?? "Unknown Bundle"
    }
}
