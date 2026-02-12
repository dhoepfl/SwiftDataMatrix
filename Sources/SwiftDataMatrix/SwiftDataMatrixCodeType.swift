//
//  SwiftDataMatrixCodeType.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// Specifies the special type markers to use for the DataMatrix code.
public enum SwiftDataMatrixCodeType {
    /// No special type marker. Generic DataMatrix code.
    case `default`

    /// Marker for GS1 DataMatrix codes.
    case gs1

    /// Marker for reader programming codes.
    case readerProgramming

    /// Marker for ISO/IEC 15434 format 05 codes.
    case format05

    /// Marker for ISO/IEC 15434 format 06 codes.
    case format06
}
