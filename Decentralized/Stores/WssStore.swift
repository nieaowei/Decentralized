import DecentralizedFFI
import SwiftUI

@Observable
@MainActor
class WssStore {
    private var wss: EsploraWss
    
    var status: EsploraWss.Status = .disconnected
    var fastFee: UInt64 = 0
  
    init(url: URL) {
        wss = EsploraWss(url: url)
    }
    
    func updateUrl(_ url: URL) async {
        
        let currentWss = wss
        
        // 先断开当前连接
        await currentWss.disconnect()
        
        // 创建新的WebSocket连接
        wss = EsploraWss(url: url)
        
        // 设置回调
        await wss.setOnStatus { status in
            Task { @MainActor in
                self.handleStatus(status: status)
            }
        }
        
        await wss.setOnFees { fees in
            Task { @MainActor in
                self.handleFees(fees: fees)
            }
        }
        
        // 连接新的WebSocket
        await connect()
    }
    
    func connect() async {
        if status == .disconnected {
            let wss = self.wss
            
            // 设置回调
            await wss.setOnStatus { [weak self] status in
                Task { @MainActor in
                    self?.handleStatus(status: status)
                }
            }
            
            await wss.setOnFees { [weak self] fees in
                Task { @MainActor in
                    self?.handleFees(fees: fees)
                }
            }
            
            await wss.connect()
        }
    }
    
    func asyncStream() async -> AsyncStream<EsploraWssData>? {
        return await wss.asyncStream
    }
    
    func disconnect() async {
        let wss = self.wss
        status = .disconnected
        await wss.disconnect()
    }
    
    func subscribe(_ datas: [EsploraWss.SubscribeData]) async {
        let wss = self.wss
        await wss.subscribe(datas: datas)
    }
    
    private func handleStatus(status: EsploraWss.Status) {
        self.status = status
    }
    
    private func handleFees(fees: Fees) {
        if fees.fastestFee != 0 {
            fastFee = fees.fastestFee
        }
    }
}
