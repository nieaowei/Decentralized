//
//  AppError.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/27.
//

import Foundation

enum AppError: Error, LocalizedError {
    case generic(message: String)

    var description: String? {
        switch self {
        case .generic(let message):
            return message
        }
    }
    
    var errorDescription: String?{
        description
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: Error
    let guidance: String
}
