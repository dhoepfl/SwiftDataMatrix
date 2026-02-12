//
//  EncodingState.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// State of the encoding state machine.
class EncodingState {
    /// The requested symbol code form. (Square or Rectancular)
    let codeForm: SwiftDataMatrixCodeForm


    /// The remaining data to encode.
    var data: Data

    /// The already encoded data.
    var encoded: Data


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
        self.encoded = Data()
        self.encoder = .ascii
    }
}
