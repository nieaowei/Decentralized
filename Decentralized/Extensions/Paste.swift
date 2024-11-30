//
//  Paste.swift
//  Decentralized
//
//  Created by Nekilc on 2024/11/30.
//

import AppKit


func copyToClipboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}
