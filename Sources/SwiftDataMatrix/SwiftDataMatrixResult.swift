//
//  SwiftDataMatrixResult.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation

/// Result of the DataMatrix encoding.
public struct SwiftDataMatrixResult {
    /// The image data of the DataMatrix code.
    ///
    /// Each bit represents one pixel (0 meaning black), starting in the top left, running line by line until the bottom right.
    /// If width is not evenly divisible by 8, the last byte of a line contains padding bits.
    ///
    /// The image contains all DataMatrix pixels, including finder patterns but without quiet zones.
    public let bitmap: Data

    /// Convenience information: Number of bytes per row used in `bitmap`.
    public let bytesPerRow: Int

    /// The width of the code/image.
    public let width: Int

    /// The height of the code/image.
    public let height: Int
}

