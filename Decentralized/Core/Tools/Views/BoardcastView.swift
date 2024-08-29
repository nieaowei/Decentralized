//
//  BoardcastView.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/19.
//

import SwiftUI

struct BroadcastView: View {
    @State var psbtHex: String = ""
    @State var sigedHex: String = ""
    var body: some View {
        HStack{
            VStack{
                VSplitView {
                  
                }
                .frame(minHeight: 360)
                VStack {
                    HStack {
                        Spacer()
                        Button("Sign") {}
                    }
                }
            }
            VStack{
                Text(verbatim: "RIght")
            }
            .frame(width: .infinity)
        }
    }
}

#Preview {
    BroadcastView()
}
