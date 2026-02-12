//
//  EncoderResult.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// Stores the result of encoding the input data into DataMatrix encoded code words.
internal struct EncoderResult {
    /// The encoded data.
    let encodedData: Data

    /// The symbol size choosen to store that data.
    let dataMatrixSymbolInfo: SymbolInfo
}
