//
//  ContactPicker.swift
//  Decentralized
//
//  Created by Nekilc on 2025/6/17.
//

import SwiftData
import SwiftUI

struct ContactPicker: View {
    @Environment(AppSettings.self) var settings
    @Environment(\.modelContext) var ctx
    @Environment(\.dismiss) var dismiss

    @State
    private var search: String = ""

//    @Binding
//    var selected: Contact?

    @State
    private var selectedId: UUID? = nil

    var onSelected: (_ contact: Contact) -> Void

    var body: some View {
        NavigationView {
            VStack {
                ContactPickerInner(settings, search: search, selected: $selectedId)
                HStack {
                    Button("Cancel", action: { dismiss() })
                    Button("Confirm", action: onConfirm)
                        .disabled(selectedId == nil)
                        .buttonStyle(.glass)
                }
            }
        }
        .searchable(text: $search, prompt: "Label or Address")
    }

    func onConfirm() {
        guard case .success(let contact) = Contact.fetchOneById(ctx: ctx, id: selectedId!) else {
            return
        }
        guard let contact else {
            return
        }
//        selected = contact
        onSelected(contact)
        DispatchQueue.main.async {
            dismiss()
        }
    }
}

struct ContactPickerInner: View {
    @Query
    private var contacts: [Contact]

    @Binding
    private var selected: UUID?

    @State private var sortOrder: [KeyPathComparator] = [KeyPathComparator(\Contact.lastUsedTs, order: .reverse)]

    init(_ settings: AppSettings, search: String, selected: Binding<UUID?>) {
        _contacts = Query(filter: Contact.predicate(search: search, network: settings.network))
        _selected = selected
    }

    var body: some View {
        Table(of: Contact.self, selection: $selected, sortOrder: $sortOrder) {
            TableColumn("Label", value: \.name)
            TableColumn("Address") { contact in
                Text(verbatim: contact.addr)
                    .truncationMode(.middle)
            }
        } rows: {
            ForEach(contacts) { contact in
                TableRow(contact)
            }
        }
    }
}

// #Preview {
//    ContactPicker()
// }
