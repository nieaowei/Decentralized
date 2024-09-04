//
//  MonitorList.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import SwiftUI

struct MonitorList: View {
    var body: some View {
        List {
            MonitorListItem()
            MonitorListItem()
            MonitorListItem()
            Button(action: {}, label: {
                Image(systemName: "plus.circle")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            })
        }
        .listStyle(.automatic)
    }
}


struct MonitorListItem:View {
    var body: some View {
        Text(verbatim: "123")
    }
}

#Preview {
    MonitorList()
}
