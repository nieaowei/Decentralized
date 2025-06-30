//
//  MempoolMonitor.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import DecentralizedFFI
import SwiftData
import SwiftUI

enum MempoolMonitorTab: Hashable {
    case ordinalFilter(OrdinalTableView.Filter)
    case collection
}

struct MempoolMonitor: View {
    @Environment(\.modelContext) var ctx
    @Environment(WalletStore.self) var wallet
    @Environment(Esplora.self) var esploraClient

    let ts: UInt64 = 0

    @State private var sortOrder = [KeyPathComparator(\MempoolOrdinal.createTs, order: .reverse)]

    @State var selections: Set<MempoolOrdinal.ID> = Set()

    @State var url: String? = nil

//    @State var filter: OrdinalTableView.Filter = .all
    @State var tabIndex: MempoolMonitorTab = .ordinalFilter(.all)
    @State var search: String = ""

    @State var showAdd: Bool = false

    var body: some View {
        VStack {
            switch tabIndex {
            case .collection: CollectionView()
            case .ordinalFilter(let filter): OrdinalTableView(filter: filter, search: search, selections: $selections, sortOrder: $sortOrder)
            }
        }
        .searchable(text: $search, placement: .automatic)
        .toolbar(content: {
            WalletStatusToolbar()
            ToolbarItemGroup(placement: .secondaryAction) {
                Picker("Filter", selection: $tabIndex) {
                    Text("All").tag(MempoolMonitorTab.ordinalFilter(.all))
                    Text("History").tag(MempoolMonitorTab.ordinalFilter(.used))
                    Text("Rune").tag(MempoolMonitorTab.ordinalFilter(.rune))
                    Text("Inscription").tag(MempoolMonitorTab.ordinalFilter(.inscription))
                    Text("Collection").tag(MempoolMonitorTab.collection)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        })
        .onAppear {
            let now = UInt64(Date().timeIntervalSince1970) - 3600
            try! ctx.delete(model: MempoolOrdinal.self, where: #Predicate { o in
                o.createTs < now
            })
        }
        .sheet(isPresented: $showAdd) {
            CustomBuyAddView(isPresented: $showAdd)
        }
    }
}
