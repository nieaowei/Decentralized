//
//  OrdinalList.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/16.
//

import SwiftData
import SwiftUI

struct OrdinalTableView: View {
    enum Filter: String {
        case all, used, rune, inscription, fund
    }

    @Query
    var ordinals: [Ordinal]

    @Binding var selections: Set<Ordinal.ID>
    @Binding var sortOrder: [KeyPathComparator<Ordinal>]

    var selectedOrdinals: [Ordinal] {
        selections.compactMap { id in
            ordinals.first(where: { $0.id == id })
        }
    }

    init(
        filter: Filter,
        search: String,
        selections: Binding<Set<Ordinal.ID>>,
        sortOrder: Binding<[KeyPathComparator<Ordinal>]>
    ) {
        _selections = selections
        _sortOrder = sortOrder
        let search = search.lowercased()
        var p: Predicate<Ordinal>
        switch filter {
        case .all:
            p = Ordinal.predicate(search: search)
        case .used:
            p = Ordinal.predicate(search: search, isUsed: true)
        case .rune:
            p = Ordinal.predicate(search: search, type: .rune)
        case .inscription:
            p = Ordinal.predicate(search: search, type: .inscription)
        case .fund:
            p = Ordinal.predicate(search: search, type: .fund)
        }
        _ordinals = Query(filter: p, sort: \.createTs, order: .reverse, animation: .default)
    }

    var body: some View {
        Table(of: Ordinal.self, selection: $selections, sortOrder: $sortOrder) {
            TableColumn("OutPoint") { ordinal in
                Text(verbatim: ordinal.outpoint)
                    .truncationMode(.middle)
            }
            TableColumn("Name") { ordinal in
                Text(verbatim: ordinal.displayName)
                    .truncationMode(.middle)
            }
            TableColumn("Amount") { ordinal in
                Text(ordinal.displayAmount)
            }
            TableColumn("Value") { ordinal in
                if ordinal.amountWithDiv > 1 {
                    Text(verbatim: "\(ordinal.value.formattedSatoshis()) (\(ordinal.avgValue.displaySatsUnit))")
                } else {
                    Text(verbatim: "\(ordinal.value.formattedSatoshis())")
                }
            }
            TableColumn("Date") { ordinal in
                Text(verbatim: ordinal.displayDate)
            }
        } rows: {
            ForEach(ordinals) { ordinal in
                TableRow(ordinal)
                    .selectionDisabled(enableSelection(ordinal: ordinal))
                    .contextMenu {
                        NavigationLink("Buy") {
                            BuyScreen(type: ordinal.type == .rune ? .rune : .inscription, ordinals: selectedOrdinals)
                        }
                        if selections.count <= 1 {
                            Link("Open in Safari", destination: URL(string: "https://ordinals.com/output/\(ordinal.outpoint)")!)
                            Button("Copy OutPoint") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(ordinal.outpoint, forType: .string)
                            }
                            Button("Copy Ordinal ID"){
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(ordinal.ordinalId, forType: .string)
                            }
                        }
                    }
            }
        }
    }

    func enableSelection(ordinal: Ordinal) -> Bool { // only same type
        selections.count > 1 && selectedOrdinals.contains(where: { $0.type != ordinal.type })
    }
}
