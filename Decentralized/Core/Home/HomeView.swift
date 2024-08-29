//
//  HomeView.swift
//
//  Created by Nekilc on 2024/5/27.
//

import SwiftUI

enum Sections: Hashable {
    case wallet(_ dest: WalletSections)
    case tools(_ dest: ToolSections)

    var title: String {
        switch self {
        case .wallet:
            "Wallet"
        case .tools:
            "Tools"
        }
    }

    static var allCases: [Sections] {
        [.wallet(.me), .tools(.broadcast)]
    }
}

enum WalletSections: Hashable {
    case me, utxos, transactions, contacts

    case send(selected: Set<String>)

    static var allCases: [WalletSections] {
        [.me, .utxos, .transactions, .send(selected: .init()), .contacts]
    }

    var icon: String {
        switch self {
        case .me: "person"
        case .utxos: "bitcoinsign"
        case .transactions: "dollarsign"
        case .send: "paperplane"
        case .contacts: "person.2"
        }
    }

    var title: String {
        switch self {
        case .me: "Me"
        case .utxos: "Utxos"
        case .transactions: "Transactions"
        case .send: "Send"
        case .contacts: "Contacts"
        }
    }
}

enum ToolSections: String, Hashable, CaseIterable {
    case broadcast
    // speedUp, cancelTx, monitor

    static var allCases: [ToolSections] {
        [.broadcast]
    }

    var title: String {
        switch self {
        case .broadcast:
            "Broadcast"
        }
    }

    var icon: String {
        switch self {
        case .broadcast: "person"
        }
    }
}

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var global: GlobalViewModel

    @State var isFirst: Bool = true

    @State var walletVm: WalletViewModel = .init(global: .live)
    @State var mempool: MempoolService = .init()
    @State var showPop: Bool = false

    var body: some View {
        NavigationSplitView {
            SiderbarView(tabIndex: $global.tabIndex)
        }
        detail: {
            switch global.tabIndex {
            case .wallet(let dest):
                switch dest {
                case .me:
                    MeView(walletVm: walletVm)
                        .navigationTitle(dest.title)
                case .utxos:
                    UtxosView(walletVm: walletVm)
                        .navigationTitle(dest.title)
                case .transactions:
                    TransactionView(walletVm: walletVm)
                        .navigationTitle(dest.title)
                case .send(let selected):
                    SendView(walletVm: walletVm, selectedUtxos: selected)
                        .navigationTitle(dest.title)
                case .contacts:
                    ContactView()
                        .navigationTitle(dest.title)
                }
            case .tools(let dest):
                switch dest {
                case .broadcast:
                    BroadcastView()
                }
            }
        }

        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Text(verbatim: "\(global.wss.fastfee) sats/vB")
                Text(verbatim: "\(global.balance.displayBtc)")
                SyncStateView(synced: $global.walletSyncState)
                    .onTapGesture {
                        global.walletSyncState = .syncing
                    }
                WssStatusView(status: $global.wss.status)
            }
        }
        .alert(isPresented: $global.showAlert) {
            Alert(
                title: Text("HomeView Error"),
                message: Text(global.error?.description ?? global.walletSyncState.description),
                dismissButton: .default(Text("OK")) {
                    global.error = nil
                }
            )
        }
        .onChange(of: scenePhase) {
            if scenePhase == ScenePhase.active {
                logger.info("active")
            }
        }
        .task {
            if isFirst {
                await global.sync()
                isFirst = false
            }
        }
        .task(id: global.wss.status) {
            if global.wss.status == .disconnected {
                global.wss.connect()
            }
        }
        .task(id: global.wss.status) {
            if global.wss.status == .connected {
                global.wss.trackAddress(global.payAddress)
                if global.walletSyncState == .synced { // Track tx after Syned
                    for tx in walletVm.transactions {
                        if !tx.isComfirmed {
                            logger.info("Track unconfirmed: \(tx.id)")
                            global.wss.trackTransaction(tx.id)
                        }
                    }
                }
            }
        }
        .task(id: global.walletSyncState) {
            if global.walletSyncState == .synced {
                walletVm.refresh()
                if global.wss.status == .connected {
                    for tx in walletVm.transactions {
                        if !tx.isComfirmed {
                            logger.info("Track unconfirmed: \(tx.id)")
                            global.wss.trackTransaction(tx.id)
                        }
                    }
                }
            }
            if global.walletSyncState == .syncing {
                await global.sync()
            }
        }
        // Handle wss response
        .task(id: global.wss.newTranactions) {
            if !global.wss.newTranactions.isEmpty {
                print("New: \(global.wss.newTranactions)")
                global.wss.newTranactions.removeAll()
                NotificationManager().sendNotification(title: "New Transaction", subtitle: "", body: "")
                await global.resync()
            }
        }
        .task(id: global.wss.rmTranactions) {
            if !global.wss.rmTranactions.isEmpty {
                print("Removed: \(global.wss.rmTranactions)")
                global.wss.rmTranactions.removeAll()
                await global.resync()
            }
        }
        .task(id: global.wss.confirmedTranactions) {
            if !global.wss.confirmedTranactions.isEmpty {
                print("Confirmed: \(global.wss.confirmedTranactions)")
                global.wss.confirmedTranactions.removeAll()
                NotificationManager().sendNotification(title: "Transaction Comfirmed", subtitle: "", body: "")
                await global.resync()
            }
        }
    }
}

struct SiderbarView: View {
    @Binding var tabIndex: Sections

    var body: some View {
        List(selection: $tabIndex) {
            ForEach(Sections.allCases, id: \.title) { sections in
                Section(sections.title) {
                    switch sections {
                    case .wallet:
                        ForEach(WalletSections.allCases, id: \.title) { walletItem in
                            if case Sections.wallet(let dest) = tabIndex {
                                if dest.title == walletItem.title {
                                    NavigationLink(value: tabIndex) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                } else {
                                    NavigationLink(value: Sections.wallet(walletItem)) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                }
                            } else {
                                NavigationLink(value: Sections.wallet(walletItem)) {
                                    Label(walletItem.title, systemImage: walletItem.icon)
                                }
                            }
                        }
                    case .tools:
                        ForEach(ToolSections.allCases, id: \.title) { walletItem in
                            if case Sections.tools(let dest) = tabIndex {
                                if dest.title == walletItem.title {
                                    NavigationLink(value: tabIndex) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                } else {
                                    NavigationLink(value: Sections.tools(walletItem)) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                }
                            } else {
                                NavigationLink(value: Sections.tools(walletItem)) {
                                    Label(walletItem.title, systemImage: walletItem.icon)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SyncStateView: View {
    @Binding var synced: WalletSyncState
    var body: some View {
        Image(systemName: sign().0)
            .foregroundColor(sign().1)
            .foregroundColor(.green)
            .symbolEffect(.pulse.wholeSymbol, isActive: sign().2)
    }

    func sign() -> (String, Color, Bool) {
        switch synced {
        case .error:
            ("circle.fill", .red, false)
        case .notStarted:
            ("circle.fill", .yellow, false)
        case .synced:
            ("circle.fill", .green, false)
        case .syncing:
            ("circle.fill", .green, true)
        }
    }
}

struct WssStatusView: View {
    @Binding var status: MempoolService.Status
    var body: some View {
        Image(systemName: sign().0)
            .foregroundColor(sign().1)
            .foregroundColor(.green)
            .symbolEffect(.pulse.wholeSymbol, isActive: sign().2)
    }

    func sign() -> (String, Color, Bool) {
        switch status {
        case .disconnected:
            ("bolt.fill", .red, false)
        case .connecting:
            ("bolt.fill", .orange, true)
        case .connected:
            ("bolt.fill", .orange, false)
        }
    }
}

#Preview {
    HomeView(global: .init())
}
