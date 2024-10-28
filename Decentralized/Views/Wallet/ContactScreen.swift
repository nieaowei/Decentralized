//
//  ContactView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/5/31.
//

import DecentralizedFFI
import SwiftData
import SwiftUI

struct ContactScreen: View {
    
    @Query private var contacts: [Contact]

    @Environment(\.modelContext) private var modelCtx

    @State private var QRData: String? = nil
    @State private var showAddContact: Bool = false
    
    init() {
        var d = FetchDescriptor<Contact>()
//        d.includePendingChanges = false
        _contacts = Query(d, animation: .default)
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
                            Button {
                                modelCtx.delete(contact)
                            } label: {
                                Image(systemName: "trash")
                                Text(verbatim: "Delete")
                            }
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

    @State private var contact: Contact = .init(addr: "", name: "")

    @State private var addrError: String?

    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Name", text: $contact.name)
                    TextField("Address", text: $contact.addr)
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
        print(modelCtx.autosaveEnabled)
        guard case .success = Address.from(address: contact.addr, network: settings.network.toBitcoinNetwork()).inspectError({ _ in
            addrError = "Invalid Address"
        }) else {
            return
        }

        _ = modelCtx.upsert(contact)

        dismiss()
    }
}

#Preview {
    ContactScreen()
        .modelContainer(for: Contact.self)
}
