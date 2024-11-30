//
//  MempoolMonitor.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import DecentralizedFFI
import SwiftData
import SwiftUI

struct MempoolMonitor: View {
    @Environment(\.modelContext) var ctx
    @Environment(WalletStore.self) var wallet
    @Environment(EsploraClientWrap.self) var esploraClient

    let ts: UInt64 = 0

    @State private var sortOrder = [KeyPathComparator(\MempoolOrdinal.createTs, order: .reverse)]

    @State var selections: Set<MempoolOrdinal.ID> = Set()

    @State var url: String? = nil

    @State var filter: OrdinalTableView.Filter = .all
    @State var search: String = ""

    @State var showAdd: Bool = false
    
    var body: some View {
        VStack {
            OrdinalTableView(filter: filter, search: search, selections: $selections, sortOrder: $sortOrder)
        }
        .searchable(text: $search, placement: .automatic)
        .toolbar(content: {
            WalletStatusToolbar()
            ToolbarItemGroup(placement: .secondaryAction) {
                Picker("Filter", selection: $filter) {
                    Text("All").tag(OrdinalTableView.Filter.all)
                    Text("History").tag(OrdinalTableView.Filter.used)
                    Text("Rune").tag(OrdinalTableView.Filter.rune)
                    Text("Inscription").tag(OrdinalTableView.Filter.inscription)
                    Text("Fund").tag(OrdinalTableView.Filter.fund)
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
