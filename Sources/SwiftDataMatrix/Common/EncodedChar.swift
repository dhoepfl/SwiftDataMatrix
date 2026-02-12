//
//  EncodedChar.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-12.
//

import Foundation

/// Text mode encoders sometimes need to take back some encoding steps before they complete.
/// This structure is used to store the characters encoded and their encoding until it is clear
/// whether the encoder can use the encoding step or not.
internal struct EncodedChar {
    /// The value that is encoded.
    let ch: UInt8

    /// The encoded representation of the value in `ch`.
    let bytes: [UInt8]
}
