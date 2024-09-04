//
//  HomeView.swift
//
//  Created by Nekilc on 2024/5/27.
//

import SwiftUI

struct HomeDetailView: View {
    var route: Route
    
    var body: some View {
        switch route {
        case .wallet(let dest):
            switch dest {
            case .me:
                MeView()
                    .navigationTitle(dest.title)
            case .utxos:
                UtxosView()
                    .navigationTitle(dest.title)
            case .transactions:
                TransactionView()
                    .navigationTitle(dest.title)
            case .send(let selected):
                SendView(selectedOutpoints: selected)
                    .navigationTitle(dest.title)
            case .contacts:
                ContactView()
                    .navigationTitle(dest.title)
            }
        case .tools(let dest):
            switch dest {
            case .broadcast:
                BroadcastView()
                    .navigationTitle(dest.title)
            case .sign:
                SignView()
                    .navigationTitle(dest.title)
            }
        }
    }
}

struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Environment(GlobalStore.self) var global: GlobalStore
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(\.showError) private var showError

    @State var isFirst: Bool = true

    @State var wss: EsploraWss = .init()
    @State var showPop: Bool = false
    @State var route: Route = .wallet(.me)
    @State var routes: [Route] = []

    var body: some View {
        NavigationSplitView {
            SiderbarView(route: $route)
        }
        detail: {
            NavigationStack(path: $routes) {
                HomeDetailView(route: route)
                    .navigationDestination(for: Route.self) { route in
                        HomeDetailView(route: route)
                    }
            }
            .onNavigate { navType in
                print("ada")
                switch navType {
                case .push(let route):
                    routes.append(route)
                case .unwind(let route):
                    if route == .wallet(.me) {
                        routes = []
                    } else {
                        guard let index = routes.firstIndex(where: { $0 == route }) else { return }
                        routes = Array(routes.prefix(upTo: index + 1))
                    }
                }
            }
            .onChange(of: route, initial: true) {
                print("route: \(route)")
            }
            .onChange(of: routes) {
                print(routes)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Text("\(global.fastFee) sats/vB")
                Text("\(wallet.balance.displayBtc)")
                SyncStateView(synced: wallet.syncStatus)
                    .onTapGesture {
                        wallet.syncStatus = .syncing
                    }
//                WssStatusView(status: global.status)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == ScenePhase.active {
                logger.info("active")
            }
        }
        .task {
            do {
                if isFirst {
                    try await wallet.sync()
                    isFirst = false
                }
            } catch {
                showError(error, "Sync Retry")
            }
        }

//        .task(id: global.status) {
//            if global.status == .disconnected {
//                global.wss.connect()
//            }
//        }
//        .task(id: global.wss.status) {
//            if global.wss.status == .connected {
//                global.wss.trackAddress(global.payAddress)
//                if global.walletSyncState == .synced { // Track tx after Syned
//                    for tx in wallet.transactions {
//                        if !tx.isComfirmed {
//                            logger.info("Track unconfirmed: \(tx.id)")
//                            global.wss.trackTransaction(tx.id)
//                        }
//                    }
//                }
//            }
//        }
//        .task(id: wallet.syncStatus) {
//            if wallet.syncStatus == .synced {
        ////                wallet.refresh()
//                if global.status == .connected {
//                    for tx in wallet.transactions {
//                        if !tx.isComfirmed {
//                            logger.info("Track unconfirmed: \(tx.id)")
//                            global.trackTransaction(tx.id)
//                        }
//                    }
//                }
//            }
//            if wallet.syncStatus == .syncing {
//                await global.sync()
//            }
//        }
        // Handle wss response
//        .task(id: global.wss.newTranactions) {
//            if !global.wss.newTranactions.isEmpty {
//                print("New: \(global.wss.newTranactions)")
//                global.wss.newTranactions.removeAll()
//                NotificationManager.sendNotification(title: "New Transaction", subtitle: "", body: "")
//                await global.resync()
//            }
//        }
//        .task(id: global.wss.rmTranactions) {
//            if !global.wss.rmTranactions.isEmpty {
//                print("Removed: \(global.wss.rmTranactions)")
//                global.wss.rmTranactions.removeAll()
//                await global.resync()
//            }
//        }
//        .task(id: global.wss.confirmedTranactions) {
//            if !global.wss.confirmedTranactions.isEmpty {
//                print("Confirmed: \(global.wss.confirmedTranactions)")
//                global.wss.confirmedTranactions.removeAll()
//                NotificationManager.sendNotification(title: "Transaction Comfirmed", subtitle: "", body: "")
//                await global.resync()
//            }
//        }
    }
}

struct SiderbarView: View {
    @Binding var route: Route

    var body: some View {
        List(selection: $route) {
            ForEach(Route.allCases, id: \.title) { sections in
                Section(sections.title) {
                    switch sections {
                    case .wallet:
                        ForEach(WalletRoute.allCases, id: \.title) { walletItem in
                            if case Route.wallet(let dest) = route {
                                if dest.title == walletItem.title {
                                    NavigationLink(value: route) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                } else {
                                    NavigationLink(value: Route.wallet(walletItem)) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                }
                            } else {
                                NavigationLink(value: Route.wallet(walletItem)) {
                                    Label(walletItem.title, systemImage: walletItem.icon)
                                }
                            }
                        }
                    case .tools:
                        ForEach(ToolRoute.allCases, id: \.title) { walletItem in
                            if case Route.tools(let dest) = route {
                                if dest.title == walletItem.title {
                                    NavigationLink(value: route) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                } else {
                                    NavigationLink(value: Route.tools(walletItem)) {
                                        Label(walletItem.title, systemImage: walletItem.icon)
                                    }
                                }
                            } else {
                                NavigationLink(value: Route.tools(walletItem)) {
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
    var synced: WalletStore.SyncStatus
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
    @Binding var status: EsploraWss.Status
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
//    HomeView(global: .init())
}
