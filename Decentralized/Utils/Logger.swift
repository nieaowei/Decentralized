
//
//  Logger.swift
//  Decentralized
//
//  Created by Nekilc on 2024/7/18.
//

import os


let logger = Logger(subsystem: "app.decentralized", category: "")


func AppLogger(cat: String) -> Logger{
    Logger(subsystem: "app.decentralized", category: cat)
}



