//
//  MempoolMonitorSettings.swift
//  Decentralized
//
//  Created by Nekilc on 2024/10/11.
//

import SwiftUI

struct MempoolMonitorSettings: View {
    @Environment(AppSettings.self) private var settings: AppSettings

    @State var runeUrl: String = "https://open-api.unisat.io/v1/indexer/runes/utxo/{0}/{1}/balance"

    @State var runeAuth: String = "9ff9f7a3469bf8802196ce3b02ebf527d9bab1c0506cec533cbed6a99ba26e1b"

    @State var runeIdPath = "$.data[0].runeid"

    @State var runeNamePath = "$.data[0].spacedRune"

    @State var runeAmountPath = "$.data[0].amount"

    @State var runeDivPath = "$.data[0].decimal"

    @State var inscriptionUrl: String = ""

    @State var inscriptionAuth: String = ""

    @State var inscriptionIdPath = ""

    @State var inscriptionNamePath = ""
    
    @State var inscriptionAmountPath = ""
    
    @State var inscriptionDivPath = ""

    @State var sameAsRune: Bool = false

    @State var ordinalTypePath: String = ""

//    @State var runeSymbolPath = "$.data[0].symbol"
    
    @State var runeFallbackUrl: String = ""
    @State var runeFallbackAuth: String = ""
    @State var runeFallbackIdPath: String = ""

    var body: some View {
        Form {
            Section("Rune") {
                TextField("Url", text: $runeUrl)
                TextField("Auth", text: $runeAuth)

                TextField("ID Path", text: $runeIdPath)
                TextField("Name Path", text: $runeNamePath)
                TextField("Amount Path", text: $runeAmountPath)
                TextField("Div Path", text: $runeDivPath)
                
                TextField("Fallback Url", text: $runeFallbackUrl)
                TextField("Fallback Auth", text: $runeFallbackAuth)
                TextField("Fallback ID Path", text: $runeFallbackIdPath)
            }
            .sectionActions {
                Button(action: onApplyRune) {
                    Text("Apply").padding(.horizontal)
                }
            }
            .onAppear {
                runeUrl = settings.runeUrl
                runeAuth = settings.runeAuth
                runeIdPath = settings.runeIdPath
                runeNamePath = settings.runeNamePath
                runeAmountPath = settings.runeAmountPath
                runeDivPath = settings.runeDivPath
                runeFallbackUrl = settings.runefallbackUrl
                runeFallbackAuth = settings.runefallbackAuth
                runeFallbackIdPath = settings.runefallbackIdPath

                sameAsRune = settings.sameAsRune
                inscriptionUrl = settings.inscriptionUrl
                inscriptionAuth = settings.inscriptionAuth
                inscriptionIdPath = settings.inscriptionIdPath
                inscriptionNamePath = settings.inscriptionNamePath
                inscriptionAmountPath = settings.inscriptionAmountPath
                inscriptionDivPath = settings.inscriptionDivPath
                
            }
            Section("Inscription") {
                Toggle("Same As Rune", isOn: $sameAsRune)
                if !sameAsRune {
                    TextField("Url", text: $inscriptionUrl)
                    TextField("Auth", text: $inscriptionAuth)
                }
                TextField("ID Path", text: $inscriptionIdPath)
                TextField("Name Path", text: $inscriptionNamePath)
                TextField("Amount Path", text: $inscriptionAmountPath)
                TextField("Div Path", text: $inscriptionDivPath)
            }
            .sectionActions {
                Button(action: onApplyInscription) {
                    Text("Apply").padding(.horizontal)
                }
            }
        }
        .formStyle(.grouped)
    }

    func onApplyRune() {
        settings.runeUrl = runeUrl
        settings.runeAuth = runeAuth
        settings.runeIdPath = runeIdPath
        settings.runeDivPath = runeDivPath
        settings.runeNamePath = runeNamePath
        settings.runeAmountPath = runeAmountPath
        settings.runefallbackUrl = runeFallbackUrl
        settings.runefallbackAuth = runeFallbackAuth
        settings.runefallbackIdPath = runeFallbackIdPath
    }
    
    func onApplyInscription() {
        if !sameAsRune {
            settings.inscriptionUrl = inscriptionUrl
            settings.inscriptionAuth = inscriptionAuth
        }
        settings.sameAsRune = sameAsRune
        settings.inscriptionIdPath = inscriptionIdPath
        settings.inscriptionNamePath = inscriptionNamePath
        settings.inscriptionAmountPath = inscriptionAmountPath
        settings.inscriptionDivPath = inscriptionDivPath
    }
}
