//
//  CpfpTx.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/24.
//

import BitcoinDevKit
import Foundation
import SwiftData

@Model
final class CpfpChain {
    @Attribute(.unique) var txid: String
    var weight: UInt64
    var fee: UInt64

    @Relationship(deleteRule: .cascade, inverse: \CpfpChain.parents) var childs: [CpfpChain] = []
    @Relationship(deleteRule: .cascade) var parents: [CpfpChain] = []

    var effectiveFeeRate: Double {
        var totalFee: UInt64 = 0
        var totalWeight: UInt64 = 0

        // 递归收集 fees
        func collectFees(chain: CpfpChain, prev: String?) {
            totalFee += chain.fee
            totalWeight += chain.weight

            // 递归遍历所有父对象
            for parent in chain.parents {
                if let prev = prev {
                    if parent.txid == prev {
                        continue
                    }
                }
                collectFees(chain: parent, prev: chain.txid)
            }

            // 递归遍历所有子对象
            for child in chain.childs {
                if let prev = prev {
                    if child.txid == prev {
                        continue
                    }
                }
                collectFees(chain: child, prev: chain.txid)
            }
        }

        // 开始计算
        collectFees(chain: self, prev: nil)

        return Double(totalFee) / (Double(totalWeight) / 4)
    }

    init(txid: String, weight: UInt64, fee: UInt64) {
        self.txid = txid
        self.weight = weight
        self.fee = fee
    }

    static func fetchChain(_ c: EsploraClient, _ startTxid: String, _ prevTxid: String?) async throws -> CpfpChain {
        let startTx = try c.getTxInfo(txid: startTxid)
        let chainStart = CpfpChain(txid: startTx.txid, weight: startTx.weight, fee: startTx.fee)

        for txin in startTx.vin {
            if let prevTxid = prevTxid {
                if prevTxid == txin.txid {
                    continue
                }
            }
            let txInfo = try c.getTxInfo(txid: txin.txid)
            if txInfo.status.confirmed {
                continue
            }

            try chainStart.parents.append(await fetchChain(c, txInfo.txid, startTxid))
        }
        for txout in startTx.vout.indices {
            let outstatus = try c.getOutputStatus(txid: startTxid, index: UInt64(txout))
            if !outstatus.spent {
                continue
            }
            let txInfo = try c.getTxInfo(txid: outstatus.txid!)
            if let prevTxid = prevTxid {
                if prevTxid == txInfo.txid {
                    continue
                }
            }
            if txInfo.status.confirmed {
                continue
            }
            try  chainStart.childs.append(await fetchChain(c, txInfo.txid, startTxid))
        }

        return chainStart
    }
}
