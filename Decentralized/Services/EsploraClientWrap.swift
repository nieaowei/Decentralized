//
//  EsploraClientWrap.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/26.
//

import DecentralizedFFI
import Observation

@Observable
class EsploraClientWrap {
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
    
    func getOutputStatus(txid: String, index: UInt64) async -> Result<OutputStatus, EsploraError> {
        Result {
            try inner.getOutputStatus(txid: txid, index: index)
        }
    }
    
    func getTx(txid: String) async -> Result<DecentralizedFFI.Transaction, EsploraError> {
        Result {
            try inner.getTx(txid: txid)
        }
    }
    
    func getTxInfo(txid: String) async -> Result<Tx, EsploraError> {
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
