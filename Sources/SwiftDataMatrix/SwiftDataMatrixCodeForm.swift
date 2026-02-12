//
//  SwiftDataMatrixCodeForm.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

/// The form the DataMatrix code should use (square or rectangular).
public enum SwiftDataMatrixCodeForm {
    /// Use only square code forms.
    case square

    /// Limit to rectangular (non-square) codes.
    case rectangular

    /// Try to use rectancular codes but use square codes if they are required or use a smaller area.
    case preferRectangular
}
