//
//  EncodingState.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// State of the encoding state machine.
class EncodingState {
    /// The data to encode.
    private let data: Data

    /// The requested symbol code form. (Square or Rectancular)
    let codeForm: SwiftDataMatrixCodeForm

    /// The current encoding position
    private var currentEncodingPos: Data.Index

    /// The already encoded data.
    private(set) var encoded: Data



    /// The number of values still pending.
    var pendingDataCount: Int {
        return currentEncodingPos.distance(to: data.endIndex)
    }

    /// A boolean value indicating whether a string has content left to encode
    var hasMoreData: Bool { pendingDataCount > 0 }



    /// Peeks for the next (or a further down) byte to be encoded.
    ///
    /// - Parameter skipping: Skip that many values from current position, then return the value.
    /// - Returns the value of the byte at the specified offset.
    func peek(skipping offset: Int = 0) -> UInt8 {
        return data[currentEncodingPos.advanced(by: offset)]
    }

    /// Retrieves the next byte to be encoded, advancing the current position.
    ///
    /// - Returns the value at the current reading point.
    func pop() -> UInt8 {
        defer { currentEncodingPos = currentEncodingPos.advanced(by: 1) }
        return data[currentEncodingPos]
    }

    /// Undoes the past pop operation.
    func undoPop() {
        self.currentEncodingPos -= 1
    }



    /// Appends the given code value to the encoded data buffer.
    ///
    /// - Parameter value: The code word to append.
    func append(encoded value: UInt8) {
        encoded.append(value)
    }


    /// The currently active encoder
    var encoder: EncoderType


    /// Constructor.
    ///
    /// Inits the state to the default (ASCII) encoder and no encoded data.
    ///
    /// - Parameter data: The data to encode.
    /// - Parameter codeForm: The requested form (square/rectangular) of the resulting code.
    init(data: Data, codeForm: SwiftDataMatrixCodeForm) {
        self.codeForm = codeForm
        self.data = data
        self.currentEncodingPos = data.startIndex
        self.encoded = Data(capacity: 1558)
        self.encoder = .ascii
    }
}
