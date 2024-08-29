//
//  HomeView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/27.
//

import SwiftUI

enum Sections: Hashable {
    case wallet(dest: WalletSec)
    case tools(dest: ToolsSec)
}

enum WalletSec: String, Hashable, CaseIterable {
    case me, utxos, transactions, send, contacts

    func icon() -> String {
        switch self {
        case .me: "person"
        case .utxos: "bitcoinsign"
        case .transactions: "dollarsign"
        case .send: "paperplane"
        case .contacts: "person.2"
        }
    }
}

enum ToolsSec: String, Hashable, CaseIterable {
    case broadcast
    // speedUp, cancelTx, monitor

    func icon() -> String {
        switch self {
        case .broadcast: "person"
        }
    }
}

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Bindable var global: GlobalViewModel

    @State private var sidebarDestination: Sections = .wallet(dest: WalletSec.me)

    @State var isFirst: Bool = true

    @State var walletVm: WalletViewModel = .init(global: .live)
    @State var mempool: MempoolService = .init()
    @State var showPop: Bool = false

    var body: some View {
        NavigationSplitView {
            SiderbarView(destination: $sidebarDestination)
        }
        detail: {
            switch sidebarDestination {
            case .wallet(let dest):
                switch dest {
                case .me:
                    MeView(walletVm: walletVm)
                        .navigationTitle("")
                case .utxos:
                    UtxosView(selected: .constant(Set<String>()), walletVm: walletVm)
                        .navigationTitle("")
                case .transactions:
                    TransactionView(walletVm: walletVm)
                        .navigationTitle("")
                case .send:
                    SendView(walletVm: walletVm)
                        .navigationTitle("")
                case .contacts:
                    ContactView()
                        .navigationTitle("")
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
//                global.wss.connect()
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
    @Binding var destination: Sections

    var body: some View {
        List(selection: $destination) {
            Section("Wallet") {
                ForEach(WalletSec.allCases, id: \.self) { walletItem in
                    NavigationLink(value: Sections.wallet(dest: walletItem)) {
                        Label(walletItem.rawValue.capitalized, systemImage: walletItem.icon())
                    }
                }
            }
            Section("Tools") {
                ForEach(ToolsSec.allCases, id: \.self) { walletItem in
                    NavigationLink(value: Sections.tools(dest: walletItem)) {
                        Label(walletItem.rawValue.capitalized, systemImage: walletItem.icon())
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
