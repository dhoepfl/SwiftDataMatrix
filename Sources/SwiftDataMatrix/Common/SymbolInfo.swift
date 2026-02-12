//
//  SymbolInfo.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation

/// Stores the information about a possible DataMatrix code size and form.
internal struct SymbolInfo {
    /// The maximum number of data codewords the code can hold in this size/form.
    let maxDataCodewords: Int


    /// The number of columns the code uses (including finder patterns)
    let columns: Int

    /// The number of rows the code uses (including finder patterns)
    let rows: Int


    /// The number of regions the code uses horizontally for this size/form
    let regionsHorizontal: Int

    /// The number of regions the code uses vertically for this size/form
    let regionsVertical: Int


    /// The number of blocks the data codewords are split into.
    let numberOfBlocks: Int

    /// The number of reed solomon error correction codewords used per block
    let reedSolomonPerBlock: Int
}


/// Finds the smallest symbol size supported that is capable of holding at least the given amount of data.
///
/// - Parameter minCodeWords: The minimum number of data codewords the code has to be capable of storing.
/// - Parameter codeForm: The code forms (square or rectangular) that are accepted.
/// - Returns A symbol info structure for the selected form.
/// - Throws A `SwiftDataMatrixError` if no matching symbol form is available.
internal func symbolSize(minCodeWords: Int, codeForm: SwiftDataMatrixCodeForm) throws -> SymbolInfo {
    guard minCodeWords >= 0 else { throw SwiftDataMatrixError.outOfSpace }
    
    guard let symbolInfo = SupportedDataMatrixSymbolSizes.filter({ symbolInfo in
        (
            (codeForm == .preferRectangular) ||
            (codeForm == .rectangular && symbolInfo.rows != symbolInfo.columns) ||
            (codeForm == .square && symbolInfo.rows == symbolInfo.columns)
        ) && symbolInfo.maxDataCodewords >= minCodeWords
    }).first
    else { throw SwiftDataMatrixError.outOfSpace }
    
    return symbolInfo
}


/// Symbol Info for all supported DataMatrix code sizes.
fileprivate let SupportedDataMatrixSymbolSizes = [
    SymbolInfo(maxDataCodewords: 3,    columns: 10,  rows: 10,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 5),
    SymbolInfo(maxDataCodewords: 5,    columns: 18,  rows: 8,   regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 7),
    SymbolInfo(maxDataCodewords: 5,    columns: 12,  rows: 12,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 7),
    SymbolInfo(maxDataCodewords: 8,    columns: 14,  rows: 14,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 10),
    SymbolInfo(maxDataCodewords: 10,   columns: 32,  rows: 8,   regionsHorizontal: 1, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 11),
    SymbolInfo(maxDataCodewords: 12,   columns: 16,  rows: 16,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 12),
    SymbolInfo(maxDataCodewords: 16,   columns: 26,  rows: 12,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 14),
    SymbolInfo(maxDataCodewords: 18,   columns: 18,  rows: 18,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 14),
    SymbolInfo(maxDataCodewords: 22,   columns: 36,  rows: 12,  regionsHorizontal: 1, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 18),
    SymbolInfo(maxDataCodewords: 22,   columns: 20,  rows: 20,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 18),
    SymbolInfo(maxDataCodewords: 30,   columns: 22,  rows: 22,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 20),
    SymbolInfo(maxDataCodewords: 32,   columns: 36,  rows: 16,  regionsHorizontal: 1, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 24),
    SymbolInfo(maxDataCodewords: 36,   columns: 24,  rows: 24,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 24),
    SymbolInfo(maxDataCodewords: 44,   columns: 26,  rows: 26,  regionsHorizontal: 1, regionsVertical: 1, numberOfBlocks: 1,  reedSolomonPerBlock: 28),
    SymbolInfo(maxDataCodewords: 49,   columns: 48,  rows: 16,  regionsHorizontal: 1, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 28),
    SymbolInfo(maxDataCodewords: 62,   columns: 32,  rows: 32,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 36),
    SymbolInfo(maxDataCodewords: 86,   columns: 36,  rows: 36,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 42),
    SymbolInfo(maxDataCodewords: 114,  columns: 40,  rows: 40,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 48),
    SymbolInfo(maxDataCodewords: 144,  columns: 44,  rows: 44,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 56),
    SymbolInfo(maxDataCodewords: 174,  columns: 48,  rows: 48,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 1,  reedSolomonPerBlock: 68),
    SymbolInfo(maxDataCodewords: 204,  columns: 52,  rows: 52,  regionsHorizontal: 2, regionsVertical: 2, numberOfBlocks: 2,  reedSolomonPerBlock: 42),
    SymbolInfo(maxDataCodewords: 280,  columns: 64,  rows: 64,  regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 2,  reedSolomonPerBlock: 56),
    SymbolInfo(maxDataCodewords: 368,  columns: 72,  rows: 72,  regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 4,  reedSolomonPerBlock: 36),
    SymbolInfo(maxDataCodewords: 456,  columns: 80,  rows: 80,  regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 4,  reedSolomonPerBlock: 48),
    SymbolInfo(maxDataCodewords: 576,  columns: 88,  rows: 88,  regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 4,  reedSolomonPerBlock: 56),
    SymbolInfo(maxDataCodewords: 696,  columns: 96,  rows: 96,  regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 4,  reedSolomonPerBlock: 68),
    SymbolInfo(maxDataCodewords: 816,  columns: 104, rows: 104, regionsHorizontal: 4, regionsVertical: 4, numberOfBlocks: 6,  reedSolomonPerBlock: 56),
    SymbolInfo(maxDataCodewords: 1050, columns: 120, rows: 120, regionsHorizontal: 6, regionsVertical: 6, numberOfBlocks: 6,  reedSolomonPerBlock: 68),
    SymbolInfo(maxDataCodewords: 1304, columns: 132, rows: 132, regionsHorizontal: 6, regionsVertical: 6, numberOfBlocks: 8,  reedSolomonPerBlock: 62),
    SymbolInfo(maxDataCodewords: 1558, columns: 144, rows: 144, regionsHorizontal: 6, regionsVertical: 6, numberOfBlocks: 10, reedSolomonPerBlock: 62),
]
