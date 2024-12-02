//
//  Async.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import DecentralizedFFI
import Foundation
import SwiftData

func fetchOrdinalTxPairsAsync(esploraClient: EsploraClientWrap, settings: AppSettings, esploraWssTx: EsploraWssTx) async -> Result<[MempoolOrdinal], Error> {
    var datas: [MempoolOrdinal] = []
    let tx = await esploraClient.getTx(txid: esploraWssTx.id)
    guard case let .success(tx) = tx else {
        return .failure(tx.err()!)
    }

    let pairs = getSingleAnyonePayTxPair(tx: tx)

    for pair in pairs {
        if settings.sameAsRune {
            let data = Result {
                try getJsonInfoFromUrl(
                    url: settings.runeUrl,
                    auth: settings.runeAuth,
                    params: [pair.txin.previousOutput.txid.description, pair.txin.previousOutput.vout.description],
                    paths: [
                        settings.runeNamePath,
                        settings.runeIdPath,
                        settings.runeAmountPath,
                        settings.runeDivPath,
                        settings.inscriptionIdPath,
                        settings.inscriptionNamePath,
                        settings.inscriptionAmountPath,
                        settings.inscriptionDivPath,
                        settings.inscriptionNumberPath,
                    ]
                )
            }

            guard case let .success(data) = data else {
                return .failure(data.err()!)
            }

            if !data.isEmpty {
                if data[0] != nil || data[1] != nil {
                    datas.append(MempoolOrdinal(type: .rune, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: data[1] ?? "", name: data[0] ?? "", amount: data[2] ?? "1", div: data[3] ?? "0"))
                    continue
                }
                if data[4] != nil || data[5] != nil {
                    datas.append(MempoolOrdinal(type: .inscription, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: data[4] ?? "", name: data[5] ?? "", number: data[8] == nil ? 0 : (UInt64(data[8]!) ?? 0), amount: data[6] ?? "1", div: data[7] ?? "0"))
                    continue
                }
            }
            datas.append(MempoolOrdinal(type: .fund, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: "", name: ""))
            continue
        }

        let runeData = await fetchOrdinalInfo(
            url: settings.runeUrl, auth: settings.runeAuth,
            txid: pair.txin.previousOutput.txid.description,
            vout: pair.txin.previousOutput.vout.description,
            idPath: settings.runeIdPath,
            namePath: settings.runeNamePath,
            amountPath: settings.runeAmountPath,
            decimalPath: settings.runeDivPath,
            numberPath: settings.inscriptionNumberPath
        )
        guard case let .success(runeData) = runeData else {
            return .failure(runeData.err()!)
        }

        if runeData.id != nil || runeData.name != nil {
            datas.append(MempoolOrdinal(type: .rune, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: runeData.id ?? "", name: runeData.name ?? "", number: runeData.number ?? 0, amount: runeData.amount, div: runeData.decimal))
            continue
        }

        let insData = await fetchOrdinalInfo(
            url: settings.runeUrl, auth: settings.runeAuth,
            txid: pair.txin.previousOutput.txid.description,
            vout: pair.txin.previousOutput.vout.description,
            idPath: settings.inscriptionIdPath,
            namePath: settings.inscriptionNamePath,
            amountPath: settings.inscriptionAmountPath,
            decimalPath: settings.inscriptionDivPath,
            numberPath: settings.inscriptionNumberPath
        )

        guard case let .success(insData) = insData else {
            return .failure(insData.err()!)
        }

        if insData.id != nil || insData.name != nil {
            datas.append(MempoolOrdinal(type: .inscription, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: insData.id ?? "", name: insData.name ?? "", number: insData.number ?? 0, amount: insData.amount, div: insData.decimal))
            continue
        }

        datas.append(MempoolOrdinal(type: .fund, txin: pair.txin, txout: pair.txout, feeRate: esploraWssTx.feeRate, ordinalId: "", name: ""))
    }
    return .success(datas)
}

struct OrdinalInfo {
    let id: String?
    let name: String?
    let number: UInt64?
    let amount: String
    let decimal: String
}

func fetchOrdinalInfo(url: String, auth: String, txid: String, vout: String, idPath: String, namePath: String, amountPath: String, decimalPath: String, numberPath: String) async -> Result<OrdinalInfo, Error> {
    let runeData = Result {
        try getJsonInfoFromUrl(
            url: url,
            auth: auth,
            params: [txid, vout],
            paths: [idPath, namePath, amountPath, decimalPath, numberPath]
        )
    }
    guard case let .success(runeData) = runeData else {
        return .failure(runeData.err()!)
    }
    return .success(OrdinalInfo(id: runeData[0], name: runeData[1], number: runeData[4] == nil ? 0 : UInt64(runeData[4]!), amount: runeData[2] ?? "1", decimal: runeData[3] ?? "0"))
}

// func fetchRuneId(modelCtx: ModelContext, name: String, url: String, auth: String, txid: String, vout: String, idPath: String) async throws -> String? {
//    let runeid =  fetchRuneIdFromDB(modelCtx: modelCtx, name: name)
//    if let runeid {
//        return runeid
//    }
//    return try await fetchRuneIdFromUrl(url: url, auth: auth, txid: txid, vout: vout, idPath: idPath)
// }

func fetchRuneIdFromUrl(url: String, auth: String, txid: String, vout: String, idPath: String) async -> Result<String?, Error> {
    let runeData = Result {
        try getJsonInfoFromUrl(
            url: url,
            auth: auth,
            params: [txid, vout],
            paths: [idPath]
        )
    }
    .map { result in
        result[0]
    }
    print("[fetchRuneIdFromUrl] \(runeData)")
    return runeData
}

func fetchRuneIdFromDB(modelCtx: ModelContext, name: String) -> Result<String?, Error> {
    let name = name
    let fetch = #Predicate<RuneInfo> { o in
        o.name == name
    }

    return modelCtx.fetchOne(predicate: fetch, includePendingChanges: true).map { runeInfo in
        runeInfo?.id
    }
}

func fetchInscriptionNameFrom(modelCtx: ModelContext, number: UInt64) -> Result<String?, Error> {
    InscriptionCollection.fetchNameByNumber(ctx: modelCtx, number: number)
}
