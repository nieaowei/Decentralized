//
//  Global.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/3.
//

import DecentralizedFFI
import SwiftUI


@Observable
public class WssStore {
    private var wss: EsploraWss
    
    @MainActor
    var status: EsploraWss.Status = .disconnected
    
    @MainActor
    var fastFee: UInt64 = 0
  
    
    init(url: URL) {
        wss = EsploraWss(url: url)
        wss.handleStatus = handleStatus
        wss.handleFees = handleFees
    }
    
    @MainActor
    func updateUrl(_ url: String) {
        wss.disconnect()
        
        wss = EsploraWss(url: URL(string: url)!)
        wss.handleStatus = handleStatus
        wss.handleFees = handleFees
        connect()
    }
    
    @MainActor
    func connect() {
        if status == .disconnected{
            wss.connect()
        }
    }
    
    func asyncStream() -> AsyncStream<EsploraWssData>? {
        return wss.asyncStream
    }
    
    @MainActor
    func disconnect() {
        status = .disconnected
        wss.disconnect()
    }
    
    func subscribe(_ datas: [EsploraWss.SubscribeData]) {
        wss.subscribe(datas: datas)
    }
    
    func handleStatus(status: EsploraWss.Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
    
    func handleFees(fees: Fees) {
        DispatchQueue.main.async {
            if fees.fastestFee != 0 {
                self.fastFee = fees.fastestFee
            }
        }
    }
    
}
