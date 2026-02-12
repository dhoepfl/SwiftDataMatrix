//
//  EncoderType.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// The list of known encoders.
internal enum EncoderType: CaseIterable {
    /// ASCII encoder.
    /// Encodes all characters with a medium efficiency, very efficient for double digits.
    case ascii

    /// C40 encoder.
    /// Encodes all characters with high efficient for upper case texts, and efficient for digits.
    /// Inefficient for other characters.
    case c40

    /// Text encoder.
    /// Encodes all characters with high efficient for lower case texts, and efficient for digits.
    /// Inefficient for other characters.
    case text

    /// X12 encoder.
    /// High efficency for digits, upper case texts, and a few special characters.
    /// Cannot encode other characters.
    case x12

    /// EDIFACT encoder.
    /// High efficency for digits, upper and lower case texts, and a several special characters.
    /// Cannot encode other characters.
    case edifact

    /// Base 256 encoder.
    /// Encodes all values using 1 code word per value, not efficient for texts but can be best for binary data.
    case base256


    /// States if the encoder needs a special marker to return to ASCII encoding.
    var requiresSwitchToAscii: Bool {
        switch self {
        case .ascii: return false
        case .c40: return true
        case .text: return true
        case .x12: return true
        case .edifact: return false
        case .base256: return false
        }
    }


    /// Encodes the next few bytes in the current encoder.
    ///
    /// Takes the current state into account when it decides wether to stop or to continue encoding.
    /// Modifies the state.
    ///
    /// - Parameter state: The currenct encoding state. This state is updated by the encoder.
    /// - Throws An `SwiftDataMatrixError` if encoding detects an unrecoverable error.
    func encode(_ state: EncodingState) throws {
        switch self {
        case .ascii: ASCIIEncoder.encode(state)
        case .c40: try TextModeEncoder.encode(state, encoder: C40Encoder.encode(ch:))
        case .text: try TextModeEncoder.encode(state, encoder: TextEncoder.encode(ch:))
        case .x12: X12Encoder.encode(state)
        case .edifact: try EDIFACTEncoder.encode(state)
        case .base256: try Base256Encoder.encode(state)
        }
    }
}
