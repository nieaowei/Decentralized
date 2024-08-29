//
//  ContactView.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/31.
//

import SwiftData
import SwiftUI

struct ContactView: View {
    @Query var contacts: [Contact]

    @Environment(\.modelContext) private var modelCtx

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
                    TextField("Address", text: Binding(get: {
                        contact.addr
                    }, set: { newVal in
                        contact.addr = newVal
                    }))
                    .textFieldStyle(.roundedBorder)
                    .truncationMode(.middle)
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
            .contextMenu {
                Button {
                    modelCtx.insert(Contact(addr: "", name: ""))
                } label: {
                    Image(systemName: "plus.circle")
                    Text(verbatim: "Add")
                }
            }
            .controlSize(.large)
        }
    }

    func addContact(name: String, addr: String) {
        modelCtx.insert(Contact(addr: addr, name: name))
    }
}

#Preview {
    ContactView()
        .modelContainer(for: Contact.self)
}
