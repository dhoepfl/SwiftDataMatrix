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

    let state: EncodingState

    // Preprocessing
    if codeType == .gs1 {
        state = EncodingState(data: data, codeForm: codeForm)
        state.append(encoded: 232)

        if state.hasMoreData && state.peek() == 232 {
            _ = state.pop()
        }
    } else if codeType == .readerProgramming {
        state = EncodingState(data: data, codeForm: codeForm)
        state.append(encoded: 234)
    } else if codeType == .format05 {
        var preprocessedData = data

        if let tailRange = preprocessedData.range(of: "\u{001E}\u{0004}".data(using: .utf8)!, options: [.anchored, .backwards]),
           let range = preprocessedData.range(of: "[)>\u{001E}05\u{001D}".data(using: .utf8)!, options: [.anchored]) {
            preprocessedData.removeSubrange(tailRange)
            preprocessedData.removeSubrange(range)
        }

        state = EncodingState(data: preprocessedData, codeForm: codeForm)
        state.append(encoded: 236)
    } else if codeType == .format06 {
        var preprocessedData = data

        if let tailRange = preprocessedData.range(of: "\u{001E}\u{0004}".data(using: .utf8)!, options: [.anchored, .backwards]),
           let range = preprocessedData.range(of: "[)>\u{001E}06\u{001D}".data(using: .utf8)!, options: [.anchored]) {
            preprocessedData.removeSubrange(tailRange)
            preprocessedData.removeSubrange(range)
        }

        state = EncodingState(data: preprocessedData, codeForm: codeForm)
        state.append(encoded: 237)
    } else {
        state = EncodingState(data: data, codeForm: codeForm)
    }

    // Encode data
    while state.hasMoreData {
        let nextEncoder = suggestedEncoder(state: state)
        if nextEncoder != state.encoder {
            switch nextEncoder {
            case .base256:
                state.append(encoded: 231)
                break
            case .c40:
                state.append(encoded: 230)
                break
            case .x12:
                state.append(encoded: 238)
                break
            case .text:
                state.append(encoded: 239)
                break
            case .edifact:
                state.append(encoded: 240)
                break
            case .ascii:
                if state.encoder.requiresSwitchToAscii {
                    state.append(encoded: 254)
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
        state.append(encoded: 254)
    }
    
    // Add padding (if required)
    var pad: UInt8 = 129
    while state.encoded.count < dataMatrixSymbolInfo.maxDataCodewords {
        state.append(encoded: pad)
        let pseudoRandom = ((149 * state.encoded.count + 149) % 253) + 130
        pad = UInt8(pseudoRandom <= 254 ? pseudoRandom : (pseudoRandom - 254))
    }
    
    // Return encoded data
    return EncoderResult(encodedData: state.encoded,
                         dataMatrixSymbolInfo: dataMatrixSymbolInfo)
}
