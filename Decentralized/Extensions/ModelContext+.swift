//
//  ModelContext+.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/19.
//

import Foundation
import SwiftData

extension ModelContext {
    func fetchOne<Model: PersistentModel>(predicate: Predicate<Model>, includePendingChanges: Bool = true) -> Result<Model?, Error> {
        var p = FetchDescriptor(predicate: predicate)

        p.fetchLimit = 1
        p.includePendingChanges = includePendingChanges

        do {
            let data = try self.fetch(p)
            return .success(data.first)
        } catch {
            return .failure(error)
        }
    }

    func upsert<Model: PersistentModel>(_ model: Model) -> Result<Void, SwiftDataError> {
        self.insert(model)
        return self.persist()
    }

    func persist() -> Result<Void, SwiftDataError> {
        Result {
            try self.save()
        }
    }
}
