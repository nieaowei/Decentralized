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

    @State var QRData: String? = nil
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
                        TextField("Address", text: Binding(get: {
                            contact.addr
                        }, set: { newVal in
                            contact.addr = newVal
                        }))
                        .textFieldStyle(.roundedBorder)
                        .truncationMode(.middle)
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
            .contextMenu {
                Button {
                    modelCtx.insert(Contact(addr: "", name: ""))
                } label: {
                    Image(systemName: "plus.circle")
                    Text(verbatim: "Add")
                }
            }
            .sheet(item: $QRData, content: { data in
                VStack {
                    QRCodeView(data: data)
                    Button {
                        QRData = nil
                    } label: {
                        Text(verbatim: "Close")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.all)
            })
//            .sheet(isPresented: $showQR, content: {
//                VStack {
//                    QRCodeView(data: QRData)
//                    Button {
//                        showQR = false
//                    } label: {
//                        Text(verbatim: "Close")
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                .padding(.all)
//
//            })
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
