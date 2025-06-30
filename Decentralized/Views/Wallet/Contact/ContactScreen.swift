//
//  ContactView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/5/31.
//

import DecentralizedFFI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContactScreen: View {
    @Query
    private var contacts: [Contact]

    @Environment(\.modelContext) private var modelCtx
    @Environment(AppSettings.self) private var settings

    @State private var QRData: String? = nil
    @State private var showAddContact: Bool = false

    init(_ settings: AppSettings) {
        _contacts = Query(filter: Contact.predicate(search: "", network: settings.storage.network), sort: \.lastUsedTs, order: .reverse)
    }

    var body: some View {
        VStack {
            Table(of: Contact.self) {
                TableColumn("Label") { contact in
                    if contact.deletable {
                        TextField("Label", text: Binding(get: {
                            contact.label
                        }, set: { newName in
                            contact.label = newName
                        }))
                        .textFieldStyle(.roundedBorder)
                    } else {
                        Text(verbatim: contact.label)
                    }
                }
                .width(200)

                TableColumn("Address") { contact in
                    HStack {
                        Text(verbatim: contact.addr)
                            .textSelection(.enabled)
                        Button {
                            QRData = contact.addr
                        } label: {
                            Image(systemName: "qrcode")
                                .controlSize(.large)
                        }
                    }
                }
            } rows: {
                ForEach(contacts) { contact in
                    TableRow(contact)
                        .contextMenu {
                            if contact.deletable {
                                Button(role: .destructive) {
                                    modelCtx.delete(contact)
                                }
                                .tint(.red)
                            }
                        }
                }
            }
            .controlSize(.large)
            .onDrop(of: [.commaSeparatedText], isTargeted: nil) { providers in
                for provider in providers {
                    handleCSV(provider: provider)
                    return true
                }
                return false
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddContact = true }, label: { Label("New Contact", systemImage: "plus") })
            }
        }
        .sheet(item: $QRData) { data in
            VStack {
                QRCodeView(data: data)
                GlassButton.primary("Close") {
                    QRData = nil
                }
            }
            .padding(.all)
        }
        .sheet(isPresented: $showAddContact, onDismiss: {}, content: { AddContactView() })
    }

    func handleCSV(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) {
            let network = settings.network
//            let ctx = modelCtx
            provider.loadItem(forTypeIdentifier: UTType.commaSeparatedText.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    let contacts = try! extractContactFromCsvData(csvData: Data(contentsOf: url), network: network)
                    for contact in contacts {
                        let c = Contact(addr: contact.address, label: contact.label, network: network)
                        DispatchQueue.main.async {
                            _ = modelCtx.upsert(c)
                        }
                    }
                } else if let data = item as? Data {
                    // 某些系统版本会以 Data 包裹 URL
                    if let url = URL(dataRepresentation: data, relativeTo: nil) {
                        let contacts = try! extractContactFromCsvData(csvData: Data(contentsOf: url), network: network)
                        for contact in contacts {
                            let c = Contact(addr: contact.address, label: contact.label, network: network)
                            DispatchQueue.main.async {
                                _ = modelCtx.upsert(c)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AddContactView: View {
    @Environment(\.modelContext) private var modelCtx
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings
    @Environment(\.showError) private var showError

    @State private var name: String = ""
    @State private var addr: String = ""

    @State private var addrError: String?

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Label", text: $name)
                    TextField("Address", text: $addr)
                }
                .sectionActions {
                    if let error = addrError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    SecondaryButton("Cancel") { dismiss() }
                    GlassButton.primary("Confirm", action: onConfirm)
                }
            }
            .formStyle(.grouped)
        }
    }

    private func onConfirm() {
        guard case .success(let address) = Address.from(address: addr, network: settings.network).inspectError({ error in
            addrError = "\(error)"
        }) else {
            return
        }
        _ = modelCtx.upsert(Contact(addr: addr, label: name, minimalNonDust: address.minimalNonDust().toSat(), network: settings.network))

        dismiss()
    }
}

// #Preview {
//    ContactScreen()
//        .modelContainer(for: Contact.self)
// }
