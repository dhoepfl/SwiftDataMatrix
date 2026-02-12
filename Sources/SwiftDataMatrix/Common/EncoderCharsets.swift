//
//  EncoderCharsets.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

/// Tests the `ch` argument for being a native X12 character.
///
/// Only native X12 characters can be encoded in X12.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is native and thus can be encoded in X12.
internal func isNativeX12(_ ch: UInt8) -> Bool {
    return (
        ch == 13 || // CR
        ch == 42 || // *
        ch == 62 || // >
        ch == 32 || // Space
        (ch >= 0x30 && ch <= 0x39) || // 0-9
        (ch >= 65 && ch <= 90) // A-Z
    )
}

/// Tests the `ch` argument for being a X12 character that is native to X12 but
/// not native in C40 or Text encoding.
///
/// This values are used to prefer X12 over C40/Text encoding.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is special to the X12
internal func isSpecialToX12(_ ch: UInt8) -> Bool {
    return (
        ch == 13 || // CR
        ch == 42 || // *
        ch == 62    // >
    )
}

/// Tests the `ch` argument for being a native EDIFACT character.
///
/// Only native EDIFACT characters can be encoded in EDIFACT.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is native and thus can be encoded in EDIFACT.
internal func isNativeEDIFACT(_ ch: UInt8) -> Bool {
    return ch >= 32 && ch <= 94 // Space - ^
}

/// Tests the `ch` argument for being an extended ASCII character.
///
/// Extended ASCII characters have the highest bit set and need to be encoded in two steps:
/// First, the fact that the highest bit is set in the next character is encoded, then the
/// character is encoded as if the highest bit was 0.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is an extended ASCII character.
internal func isExtendedASCII(_ ch: UInt8) -> Bool {
    return ch >= 128
}

/// Tests the `ch` argument for being a decimal digit character.
/// Regardless of locale, this means the characters 0, 1, 2, 3, 4, 5, 6, 7, 9.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is a decimal digit character.
internal func isDigit(_ ch: UInt8) -> Bool {
    return ch >= 0x30 && ch <= 0x39
}

/// Tests the `ch` argument for being a native C40 character.
///
/// C40 can encode all values for `ch` but only native C40 can be encoded efficiently.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is native and thus can be efficiently encoded in C40.
internal func isNativeC40(_ ch: UInt8) -> Bool {
    return (
        ch == 32 || // Space
        (ch >= 0x30 && ch <= 0x39) || // 0-9
        (ch >= 65 && ch <= 90) // A-Z
    )
}

/// Tests the `ch` argument for being a native character in the Text encoding.
///
/// Text encoding can encode all values for `ch` but only native characters can beencoded efficiently.
///
/// - Parameter ch: The character to test.
/// - Returns `true` if the character is native and thus can be efficiently encoded in Text encoding.
internal func isNativeText(_ ch: UInt8) -> Bool {
    return (
        ch == 32 || // Space
        (ch >= 0x30 && ch <= 0x39) || // 0-9
        (ch >= 97 && ch <= 122) // a-z
    )
}
