//
//  HomeView.swift
//
//  Created by Nekilc on 2024/5/27.
//

import DecentralizedFFI
import LocalAuthentication
import SwiftData
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
            case .transactions(let tx):
                switch tx {
                case .list:
                    TransactionView()
                        .navigationTitle(tx.title)
                case .detail(let tx):
                    TransactionDetailView(tx: tx)
                }
            case .send(let selected):
                SendScreen(selectedOutpointIds: selected)
                    .navigationTitle(dest.title)
            case .sign:
                SignView()
                    .navigationTitle(dest.title)
            case .contacts:
                ContactScreen()
                    .navigationTitle(dest.title)
            }
        case .tools(let dest):
            switch dest {
            case .broadcast:
                BroadcastView()
                    .navigationTitle(dest.title)
            case .mempoolMonitor:
                MempoolMonitor()
                    .navigationTitle("")
            case .ordinal:
                OrdinalMintScreen()
                    .navigationTitle(dest.title)
            }
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppSettings.self) var settings
    @Environment(WssStore.self) var wss

    @Environment(\.showError) private var showError

    @Environment(EsploraClientWrap.self) private var esploraClient

    @State var syncClient: SyncClient
//    @State var wss: WssStore
    @State var wallet: WalletStore
    @State var isFirst: Bool = true

    @State var showPop: Bool = false
    @State var showBalancePop: Bool = false
    @State var route: Route = .wallet(.me)
    @State var routes: [Route] = [.wallet(.me)]

    @State
    @MainActor
    var isAuth: Bool = false

    var authCtx: LAContext = .init()

    init(_ settings: AppSettings) {
        logger.info("Init HomeView")
        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        case .EsploraWss:
            fatalError()
        }

        let syncClient = SyncClient(inner: syncClientInner)
        do{
            let walletService = try WalletService(network: settings.network, syncClient: .init(inner: syncClientInner))
            _wallet = State(wrappedValue: WalletStore(wallet: walletService))

        }catch{
            settings.isOnBoarding = true
            fatalError("error")
        }
//        _wss = State(wrappedValue: .init(url: URL(string: settings.wssUrl)!))
        _syncClient = State(wrappedValue: syncClient)
        isAuth = !settings.enableTouchID
    }

    func recurseAuth() async {
        do {
            try await LARight().authorize(localizedReason: "Use TouchID to continue")
            isAuth = true
        } catch LAError.userCancel {
            await recurseAuth()
        } catch {}
    }

    var body: some View {
        if settings.enableTouchID && !isAuth {
            VStack {}
                .onAppear {
                    Task {
                        await recurseAuth()
                    }
                }
        } else {
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
                    switch navType {
                    case .push(let route):
                        routes.append(route)
                    case .goto(let route):
                        self.route = route
                    case .unwind(let route):
                        if route == .wallet(.me) {
                            routes = []
                        } else {
                            guard let index = routes.firstIndex(where: { $0 == route }) else { return }
                            routes = Array(routes.prefix(index + 1))
                        }
                    }
                }
            }
            .environment(wallet)
            .environment(syncClient)
            .environment(wss)
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
            .task(id: wss.status) {
                if wss.status == .connected {
                    wss.subscribe([.mempoolBlock(0)])
                    wss.subscribe([.address(wallet.payAddress?.description ?? "")])
                    if wallet.syncStatus == .synced { // Track tx after Syned
                        for tx in wallet.transactions {
                            if !tx.isComfirmed {
                                wss.subscribe([.transaction(tx.id)])
                            }
                        }
                    }
                }
            }
            .task(id: wallet.syncStatus) {
                if wallet.syncStatus == .synced {
                    if wss.status == .connected {
                        for tx in wallet.transactions {
                            if !tx.isComfirmed {
                                wss.subscribe([.transaction(tx.id)])
                            }
                        }
                    }
                }
                if !isFirst && wallet.syncStatus == .notStarted {
                    do {
                        try await wallet.sync()
                    } catch {
                        showError(error, "Sync Retry")
                    }
                }
            }
            .onChange(of: wss.status) { _, newValue in
                if newValue == EsploraWss.Status.connected {
                    handleWssData()
                }
            }
            .onAppear {
                wss.connect()
            }
            .onChange(of: settings.serverUrl) {
                logger.info("serverUrl Change")
                updateSyncClientInner()
            }
            .onChange(of: settings.network) {
                logger.info("network Change")
                updateWallet()
            }
            .onChange(of: settings.changed) {
                logger.info("settings Change")
            }
            .onChange(of: settings.wssUrl) {
                logger.info("wssUrl Change")
                updateWss()
            }
        }
    }

    func updateSyncClientInner() {
        logger.info("updateSyncClientInner: \(settings.serverUrl)")
        let syncClientInner = switch settings.serverType {
        case .Esplora:
            SyncClientInner.esplora(EsploraClient(url: settings.serverUrl))
        case .Electrum:
            SyncClientInner.electrum(try! ElectrumClient(url: settings.serverUrl))
        case .EsploraWss:
            fatalError()
        }
        syncClient.inner = syncClientInner
    }

    func updateWss() {
        wss.updateUrl(settings.wssUrl)
    }

    func updateWallet() {
        updateSyncClientInner()
        wallet = WalletStore(wallet: try! WalletService(network: settings.network, syncClient: syncClient))
    }

    func handleWssData() {
        Task {
            for await data in wss.asyncStream()! {
                switch data {
                case .mempoolTx(let esploraWssTx):
                    Task {
                        if case .success(let ordinals) = await fetchOrdinalTxPairsAsync(esploraClient: esploraClient, settings: settings, esploraWssTx: esploraWssTx)
                            .inspectError({ error in
                                logger.error("[fetchOrdinalTxPairs] \(error)")
                            })
                        {
                            for ordi in ordinals {
                                
                                if ordi.type == .rune && ordi.ordinalId.isEmpty {
                                    if case .success(let runeid) = RuneInfo.fetchOneByName(ctx: ctx, name: ordi.name), let runeid {
                                        ordi.ordinalId = runeid.id
                                    }
                                }
                                _ = ctx.upsert(ordi)
                            }
                        }
                    }
                case .newTx(let esploraTx):
                    NotificationManager.sendNotification(title: NSLocalizedString("New Transaction", comment: ""), subtitle: esploraTx.id, body: "")
                    wallet.syncStatus = .notStarted
                case .txConfirmed(let string):
                    NotificationManager.sendNotification(title: NSLocalizedString("Transaction Confirmed", comment: ""), subtitle: string, body: "")
                    wallet.syncStatus = .notStarted
                case .txRemoved(let esploraTx):
                    NotificationManager.sendNotification(title: NSLocalizedString("Transaction Removed", comment: ""), subtitle: esploraTx.id, body: "")
                    wallet.syncStatus = .notStarted
                case .block(let block):
                    try! Ordinal.clearConfirmed(ctx: ctx, blockMinFeeRate: block.extras.feeRange.first!)
                }
            }
        }
    }
}

struct WalletStatusToolbar: ToolbarContent {
    @Environment(WalletStore.self) var wallet: WalletStore
    @Environment(WssStore.self) var wss

    @State var showBalancePop: Bool = false

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .confirmationAction) {
            Text("\(wss.fastFee) sats/vB")
            Text("\(wallet.balance.total.formatted)")
                .onTapGesture {
                    showBalancePop = true
                }
                .popover(isPresented: $showBalancePop) {
                    Form {
                        LabeledContent("Confirmed", value: wallet.balance.confirmed.formatted)
                        LabeledContent("Unconfirmed", value: wallet.balance.untrustedPending.formatted)
                    }
                    .padding(.all)
                }
            WalletSyncStatusView(synced: wallet.syncStatus)
                .onTapGesture {
                    wallet.updateStatus(.notStarted)
                }
            WssStatusView(status: wss.status)
        }
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

struct WalletSyncStatusView: View {
    var synced: WalletStore.SyncStatus
    var body: some View {
        Image(systemName: sign().0)
            .foregroundColor(sign().1)
//            .foregroundColor(.green)
            .aspectRatio(contentMode: .fit)
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
    var status: EsploraWss.Status
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
