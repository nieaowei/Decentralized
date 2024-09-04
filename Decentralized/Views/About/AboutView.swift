//
//  AboutView.swift
//  BTCt
//
//  Created by Nekilc on 2024/7/10.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        HStack {
            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 10)
                .padding()
            VStack {
                Text(verbatim: "Decentralized")
                    .font(.largeTitle)
                    .fontDesign(.rounded)
                Text("Version 1.0.0")
                
            }
        }
        .padding(.all)
    }
}

#Preview {
    AboutView()
}
