//
//  KeyChainService.swift
//  Decentralized
//
//  Created by Nekilc on 2024/9/18.
//

import Foundation
import Security

enum KeyServiceError: Error {
    case encodingError
    case writeError
    case decodingError
    case readError
}


enum KeyChainService {
    static func saveBackupInfo(_ backupInfo: BackupInfo) throws -> Bool {
        let encoder = JSONEncoder()
        let data = try encoder.encode(backupInfo)

        let query: [String: Any] = [
            kSecAttrService as String: "app.decentralized",
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "Mnemonic",
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func getBackupInfo() throws -> BackupInfo {
        let query: [String: Any] = [
            kSecAttrService as String: "app.decentralized",
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "Mnemonic",
            kSecReturnData as String: true,
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            throw KeyServiceError.readError
        }

        let decoder = JSONDecoder()
        let backupInfo = try decoder.decode(BackupInfo.self, from: data)
        return backupInfo
    }

    static func deleteBackupInfo() throws {
        let query: [String: Any] = [
            kSecAttrService as String: "app.decentralized",
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "Mnemonic",
            kSecReturnData as String: true,
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
