//
//  SwiftDataMatrixError.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation

/// The errors thrown by the SwiftDataMatrix API
enum SwiftDataMatrixError : Error {
    /// The data cannot be encoded in the DataMatrix code because its encoded form exceeds the maximum size.
    case outOfSpace

    /// Internal error that should never happen.
    case invalidBlockSize
}
