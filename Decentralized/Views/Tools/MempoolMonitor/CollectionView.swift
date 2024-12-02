//
//  CollectionView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/12/2.
//

import SwiftData
import SwiftUI

struct CollectionView: View {
    @Environment(\.modelContext) var modelContext

    @Query var all: [InscriptionCollection]
    @State var showAdd: Bool = false

    @State var name: String = ""
    @State var start: UInt64 = 0
    @State var end: UInt64 = 0

    @State var selectedIds: Set<PersistentIdentifier> = []

    var body: some View {
        Table(of: InscriptionCollection.self, selection: $selectedIds) {
            TableColumn("Name", value: \.name)
            TableColumn("Start", value: \.startNumber.description)
            TableColumn("End", value: \.endNumber.description)
        } rows: {
            ForEach(all) { col in
                TableRow(col)
            }
        }
        .contextMenu {
            Button("Add") {
                showAdd = true
            }
        }
        .sheet(isPresented: $showAdd) {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Start", value: $start, formatter: NumberFormatter())
                    TextField("End", value: $end, formatter: NumberFormatter())
                }
                .sectionActions {
                    Button("Confirm", action: onAdd)
                }
            }
            .formStyle(.grouped)
        }
    }

    func onAdd() {
        let col = InscriptionCollection(name: name, startNumber: start, endNumber: end)
        modelContext.insert(col)
        try! modelContext.save()
        showAdd = false
    }
}

#Preview {
    CollectionView()
}
