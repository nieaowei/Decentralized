//
//  Debug.swift
//  Decentralized
//
//  Created by Nekilc on 2025/6/28.
//

import Foundation

func debugAsyncThread(_ label: String = "") {
    var tid: UInt64 = 0
    pthread_threadid_np(nil, &tid)
    print("🧵 \(label) → Thread ID: \(tid), isMain: \(Thread.isMainThread)")
}
