//
//  CpfpTx.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/24.
//

import DecentralizedFFI
import Foundation
import SwiftData

@Model
final class CPFPChain {
    @Attribute(.unique) var txid: String

    var weight: UInt64
    var fee: UInt64

    @Relationship(deleteRule: .cascade, inverse: \CPFPChain.parents) var childs: [CPFPChain] = []
    @Relationship(deleteRule: .cascade) var parents: [CPFPChain] = []

    var effectiveFeeRate: Double {
        var totalFee: UInt64 = 0
        var totalWeight: UInt64 = 0

        func collectFees(chain: CPFPChain, prev: String?) {
            totalFee += chain.fee
            totalWeight += chain.weight

            for parent in chain.parents {
                if let prev = prev {
                    if parent.txid == prev {
                        continue
                    }
                }
                collectFees(chain: parent, prev: chain.txid)
            }

            for child in chain.childs {
                if let prev = prev {
                    if child.txid == prev {
                        continue
                    }
                }
                collectFees(chain: child, prev: chain.txid)
            }
        }

        collectFees(chain: self, prev: nil)

        return Double(totalFee) / (Double(totalWeight) / 4)
    }

    init(txid: String, weight: UInt64, fee: UInt64) {
        self.txid = txid
        self.weight = weight
        self.fee = fee
    }

    static func fetchChain(_ c: EsploraClientWrap, _ startTxid: Txid, _ prevTxid: Txid?) async -> Result<CPFPChain, Error> {

        let startTx = await c.getTxInfo(txid: startTxid)
        guard case let .success(startTx) = startTx else {
            return .failure(startTx.err()!)
        }

        let chainStart = CPFPChain(txid: startTx.txid.description, weight: startTx.weight, fee: startTx.fee)

        for txin in startTx.vin {
            if let prevTxid = prevTxid {
                if prevTxid == txin.txid {
                    continue
                }
            }
            let txInfo = await c.getTxInfo(txid: txin.txid)
            guard case let .success(txInfo) = txInfo else {
                return .failure(txInfo.err()!)
            }

            if txInfo.status.confirmed {
                continue
            }

            if case let .failure(error) = await fetchChain(c, txInfo.txid, startTxid).inspect({ chain in
                chainStart.parents.append(chain)
            }) {
                return .failure(error)
            }
        }
        for txout in startTx.vout.indices {
            let outStatus = await c.getOutputStatus(txid: startTxid, index: UInt64(txout))
            guard case let .success(outstatus) = outStatus else {
                continue
            }
            if !outstatus.spent {
                continue
            }

            let txInfo = await c.getTxInfo(txid: outstatus.txid!)

            guard case let .success(txInfo) = txInfo else {
                return .failure(txInfo.err()!)
            }

            if let prevTxid = prevTxid, prevTxid == txInfo.txid {
                continue
            }

            if txInfo.status.confirmed {
                continue
            }
            if case let .failure(error) = await fetchChain(c, txInfo.txid, startTxid).inspect({ chain in
                chainStart.childs.append(chain)
            }) {
                return .failure(error)
            }
        }

        return .success(chainStart)
    }
}

extension CPFPChain {
    static func fetchOneByTxid(ctx: ModelContext, txid: Txid) -> Result<CPFPChain?, Error> {
        let txid = txid.description
        return ctx.fetchOne<CPFPChain>(predicate: #Predicate<CPFPChain> { o in
            o.txid == txid
        })
    }
}
