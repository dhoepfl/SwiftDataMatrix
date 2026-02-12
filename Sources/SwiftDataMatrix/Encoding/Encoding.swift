//
//  Encoding.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation

/// Encodes the given data as the specified type for the given DataMatrix code form.
///
/// - Parameter data: The data that should be encoded.
/// - Parameter codeType: The DataMatrix marker to use for the data type.
/// - Parameter codeForm: The form of the DataMatrix code to use: square or rectangular.
/// - Returns The encoding result, giving the encoded data and the choosen symbol form/size.
/// - Throws A `SwiftDataMatrixError` if encoding failed.
func encode(data: Data,
            codeType: SwiftDataMatrixCodeType = .default,
            codeForm: SwiftDataMatrixCodeForm = .square) throws -> EncoderResult {
    // Encode
    let state = EncodingState(data: data, codeForm: codeForm)
    
    // Preprocessing
    if codeType == .gs1 {
        state.encoded.append(232)

        if state.data.starts(with: [232]) {
            state.data = state.data.dropFirst()
        }
    } else if codeType == .readerProgramming {
        state.encoded.append(234)
    } else if codeType == .format05 {
        state.encoded.append(236)
        
        if let tailRange = state.data.range(of: "\u{001E}\u{0004}".data(using: .utf8)!, options: [.anchored, .backwards]),
           let range = state.data.range(of: "[)>\u{001E}05\u{001D}".data(using: .utf8)!, options: [.anchored]) {
            state.data.removeSubrange(tailRange)
            state.data.removeSubrange(range)
        }
    } else if codeType == .format06 {
        state.encoded.append(237)
        
        if let tailRange = state.data.range(of: "\u{001E}\u{0004}".data(using: .utf8)!, options: [.anchored, .backwards]),
           let range = state.data.range(of: "[)>\u{001E}06\u{001D}".data(using: .utf8)!, options: [.anchored]) {
            state.data.removeSubrange(tailRange)
            state.data.removeSubrange(range)
        }
    }
    
    // Encode data
    while state.data.count > 0 {
        let nextEncoder = suggestedEncoder(data: state.data, currentEncoder: state.encoder)
        if nextEncoder != state.encoder {
            // print("Switching from encoder \(state.encoder) to \(nextEncoder)")

            switch nextEncoder {
            case .base256:
                state.encoded.append(231)
                break
            case .c40:
                state.encoded.append(230)
                break
            case .x12:
                state.encoded.append(238)
                break
            case .text:
                state.encoded.append(239)
                break
            case .edifact:
                state.encoded.append(240)
                break
            case .ascii:
                if state.encoder.requiresSwitchToAscii {
                    state.encoded.append(254)
                }
                break
            }
        }
        state.encoder = nextEncoder
        
        try state.encoder.encode(state)
    }
    
    // Check which DataMatrix size to use
    let dataMatrixSymbolInfo = try symbolSize(minCodeWords: state.encoded.count, codeForm: state.codeForm)
    
    // Append switch to ASCII, if required/space permits
    if state.encoded.count < dataMatrixSymbolInfo.maxDataCodewords &&
        state.encoder.requiresSwitchToAscii {
        state.encoded.append(254)
    }
    
    // Add padding (if required)
    var pad: UInt8 = 129
    while state.encoded.count < dataMatrixSymbolInfo.maxDataCodewords {
        state.encoded.append(pad)
        let pseudoRandom = ((149 * state.encoded.count + 149) % 253) + 130
        pad = UInt8(pseudoRandom <= 254 ? pseudoRandom : (pseudoRandom - 254))
    }
    
    // Return encoded data
    return EncoderResult(encodedData: state.encoded,
                         dataMatrixSymbolInfo: dataMatrixSymbolInfo)
}
