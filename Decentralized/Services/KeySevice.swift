//
//  KeySevice.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/24.
//

import BitcoinDevKit
import Foundation
import KeychainAccess

enum KeyServiceError: Error {
    case encodingError
    case writeError
    case decodingError
    case readError
}

 struct KeyService {
    static let shared: KeyService = .init()
    private let keychain: Keychain

    init() {
        let keychain = Keychain(service: "app.decentralized") // TODO: use `Bundle.main.displayName` or something like com.bdk.swiftwalletexample
            .label(Bundle.main.displayName)
            .synchronizable(false)
            .accessibility(.whenUnlocked)
        self.keychain = keychain
    }

    func saveBackupInfo(_ backupInfo: BackupInfo) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(backupInfo)
        keychain[data: "BackupInfo"] = data
    }

    func getBackupInfo() throws -> BackupInfo {
        guard let encryptedJsonData = try keychain.getData("BackupInfo") else {
            throw KeyServiceError.readError
        }
        let decoder = JSONDecoder()
        let backupInfo = try decoder.decode(BackupInfo.self, from: encryptedJsonData)
        return backupInfo
    }

    func deleteBackupInfo() throws {
        try keychain.remove("BackupInfo")
    }
}

