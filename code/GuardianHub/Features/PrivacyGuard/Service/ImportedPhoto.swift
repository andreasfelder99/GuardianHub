//
//  ImportedPhoto.swift
//  GuardianHub
//
//  Created by Andreas Felder on 26.01.2026.
//

import Foundation

struct ImportedPhoto: Sendable {
    let data: Data
    let filename: String?
    let source: String
}
