//
//  Monitor.swift
//  BTCt
//
//  Created by Nekilc on 2024/5/23.
//

import AppKit
import SwiftUI

struct MonitorView: View {
    @State var text = ""

    init(text: String = "") {
        self.text = text
    }

    var body: some View {
        VStack {
            TextField("ads", text: $text)
                .onPasteCommand(of: [.plainText], perform: { str in
                    print(str.description)
                })
            HSplitView(content: {
                MonitorList()

            })
        }
        .onAppear{
            NSNotification.willChangeValue(forKey: "")
        }
        
    }
}

#Preview {
    MonitorView()
}
