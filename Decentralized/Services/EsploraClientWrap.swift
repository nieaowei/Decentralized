//
//  EsploraClientWrap.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/26.
//

import DecentralizedFFI
import Observation

@Observable
class Esplora {
    private var wrap: EsploraClientWrap
    
    init(esploraClient: EsploraClient) {
        self.wrap = EsploraClientWrap(inner: esploraClient)
    }
    
    func setWrap(_ esploraClient: EsploraClient) {
        wrap = EsploraClientWrap(inner: esploraClient)
    }
    
    func getWrap() -> EsploraClientWrap {
        wrap
    }
}

struct EsploraClientWrap {
    var inner: EsploraClient
    
    init(inner: EsploraClient) {
        self.inner = inner
    }
    
    func broadcast(transaction: DecentralizedFFI.Transaction) async -> Result<Void, EsploraError> {
        Result {
            try inner.broadcast(transaction: transaction)
        }
    }
    
    func fullScan(request: DecentralizedFFI.FullScanRequest, stopGap: UInt64, parallelRequests: UInt64) async -> Result<DecentralizedFFI.Update, EsploraError> {
        Result {
            try inner.fullScan(request: request, stopGap: stopGap, parallelRequests: parallelRequests)
        }
    }
    
    func getOutputStatus(txid: Txid, index: UInt64) async -> Result<OutputStatus, EsploraError> {
        Result {
            try inner.getOutputStatus(txid: txid, index: index)
        }
    }
    
    func getTx(txid: Txid) async -> Result<DecentralizedFFI.Transaction, EsploraError> {
        Result {
            try inner.getTx(txid: txid)
        }
    }
    
    func getTxInfo(txid: Txid) async -> Result<Tx, EsploraError> {
        Result {
            try inner.getTxInfo(txid: txid)
        }
    }
    
    func sync(request: DecentralizedFFI.SyncRequest, parallelRequests: UInt64) async -> Result<DecentralizedFFI.Update, EsploraError> {
        Result {
            try inner.sync(request: request, parallelRequests: parallelRequests)
        }
    }
}
