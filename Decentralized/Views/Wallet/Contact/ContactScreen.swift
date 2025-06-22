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
//    @Environment(AppSettings.self) private var settings

    @State private var QRData: String? = nil
    @State private var showAddContact: Bool = false

    init(_ settings: AppSettings) {
        _contacts = Query(filter: Contact.predicate(search: "", network: settings.network))
    }

    var body: some View {
        VStack {
            Table(of: Contact.self) {
                TableColumn("Name") { contact in
                    TextField("Name", text: Binding(get: {
                        contact.name
                    }, set: { newName in
                        contact.name = newName
                    }))
                    .textFieldStyle(.roundedBorder)
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
                            Button(role: .destructive) {
                                modelCtx.delete(contact)
                            }
                            .tint(.red)
                        }
                }
            }
            .controlSize(.large)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showAddContact = true }, label: { Label("New Contact", systemImage: "plus") })
            }
        }
        .sheet(item: $QRData) { data in
            VStack {
                QRCodeView(data: data)
                PrimaryButton("Close") {
                    QRData = nil
                }
            }
            .padding(.all)
        }
        .sheet(isPresented: $showAddContact, onDismiss: {}, content: { AddContactView() })
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
                    TextField("Name", text: $name)
                    TextField("Address", text: $addr)
                }
                .sectionActions {
                    if let error = addrError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    SecondaryButton("Cancel") { dismiss() }
                    PrimaryButton("Confirm", action: onConfirm)
                }
            }
            .formStyle(.grouped)
        }
    }

    private func onConfirm() {
        guard case .success = Address.from(address: addr, network: settings.network.toBitcoinNetwork()).inspectError({ error in
            addrError = "\(error)"
        }) else {
            return
        }
        _ = modelCtx.upsert(Contact(addr: addr, name: name, network: settings.network))

        dismiss()
    }
}

// #Preview {
//    ContactScreen()
//        .modelContainer(for: Contact.self)
// }
