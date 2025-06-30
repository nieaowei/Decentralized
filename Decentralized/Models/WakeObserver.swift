//
//  WakeObserver.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/15.
//

import AppKit
import Combine
import Foundation
import Observation

@Observable
class WakeObserver {
    @MainActor
    var isAwake: Bool = true

    private var cancellable: AnyCancellable?

    @MainActor
    init() {
        self.cancellable = NotificationCenter.default.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Task {
                    self?.handleWake()
                }
            }
    }

    @MainActor
    private func handleWake() {
        self.isAwake = true
    }

    deinit {
        cancellable?.cancel()
    }
}
