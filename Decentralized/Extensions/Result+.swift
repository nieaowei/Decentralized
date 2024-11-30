//
//  Result+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/19.
//

import Foundation

public extension Result {
    init(_ transform: () throws -> Success) {
        do {
            self = try .success(transform())
        } catch let error as Failure {
            self = .failure(error)
        } catch {
            fatalError("\(error)")
        }
    }

    init(_ transform: () async throws -> Success) async {
        do {
            self = try .success(await transform())
        } catch let error as Failure {
            self = .failure(error)
        } catch {
            fatalError("\(error)")
        }
    }

    var isOk: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isErr: Bool {
        return !isOk
    }

    func unwrap() -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            fatalError("Unwrapped a failure: \(error)")
        }
    }

    func unwrapOr(_ defaultValue: Success) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return defaultValue
        }
    }

    func mapErr<NewFailure>(_ transform: (Failure) -> NewFailure) -> Result<Success, NewFailure> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }

    func andThen<NewSuccess>(_ transform: (Success) -> Result<NewSuccess, Failure>) -> Result<NewSuccess, Failure> {
        return flatMap(transform)
    }

    func orElse(_ transform: (Failure) -> Result<Success, Failure>) -> Result<Success, Failure> {
        switch self {
        case .success:
            return self
        case .failure(let error):
            return transform(error)
        }
    }

    func ok() -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    func err() -> Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    func mapOr<T>(_ defaultValue: T, _ transform: (Success) -> T) -> T {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure:
            return defaultValue
        }
    }

//    func fold<SuccessResult>(
//        onSuccess: (Success) -> SuccessResult,
//        onFailure: (Failure) -> SuccessResult
//    ) -> SuccessResult {
//        switch self {
//        case .success(let value):
//            return onSuccess(value)
//        case .failure(let error):
//            return onFailure(error)
//        }
//    }

    func inspect(_ transform: (Success) -> Void) -> Self {
        if case .success(let success) = self {
            transform(success)
        }
        return self
    }

    func inspectError(_ transform: (Failure) -> Void) -> Self {
        if case .failure(let error) = self {
            transform(error)
        }
        return self
    }

    func inspectErrorAsync(_ transform: (Failure) async -> Void) async -> Self {
        if case .failure(let error) = self {
            await transform(error)
        }
        return self
    }

    func inspectAsync(_ transform: (Success) async -> Void) async -> Self {
        if case .success(let success) = self {
            await transform(success)
        }
        return self
    }

    func flatMapAsync<NewSuccess>(_ transform: @escaping (Success) async -> Result<NewSuccess, Failure>) async -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let success):
            return await transform(success)
        case .failure(let failure):
            return .failure(failure)
        }
    }
}
