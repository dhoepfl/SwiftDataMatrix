//
//  SwiftDataMatrix.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation

/// Generate a DataMatrix code for a given content.
///
/// The following example creates a DataMatrix code for the content “SwiftDataMatrix”,
/// scales the returned image to 180×180 pixels, adds 10 pixels border on all sides
/// and stores that image as “SwiftDataMatrix.png”:
///
/// ```
/// import Foundation
/// import CoreGraphics
/// import UniformTypeIdentifiers
/// import SwiftDataMatrix
/// 
/// let width = 180
/// let height = 180
/// let content = "SwiftDataMatrix".data(using: .utf8)!
///
/// do {
///     // Create DataMatrix code
///     let dataMatrix = try dataMatrix(for: content)
///
///     // Create a CGImage from the data:
///
///     if let colorSpace = CGColorSpace(name: CGColorSpace.linearGray),
///        let dataProvider = CGDataProvider(data: dataMatrix.rawBitmap as CFData),
///        let cgImage = CGImage(width: dataMatrix.width,
///                              height: dataMatrix.height,
///                              bitsPerComponent: 1,
///                              bitsPerPixel: 1,
///                              bytesPerRow: dataMatrix.bytesPerRow,
///                              space: colorSpace,
///                              bitmapInfo: CGBitmapInfo.byteOrderDefault,
///                              provider: dataProvider,
///                              decode: nil,
///                              shouldInterpolate: false,
///                              intent: .saturation) {
///         // Scale result image
///         if let colorSpace = CGColorSpace(name: CGColorSpace.linearGray),
///            let context = CGContext(data: nil,
///                                    width: width + 20,
///                                    height: height + 20,
///                                    bitsPerComponent: 8,
///                                    bytesPerRow: width + 20,
///                                    space: colorSpace,
///                                    bitmapInfo: .byteOrderDefault) {
///             // Fill background (creating white border)
///             context.setFillColor(.white)
///             context.fill(CGRect(x: 0, y: 0, width: width+20, height: height+20))
///
///             // draw image to context (resizing it)
///             context.interpolationQuality = .none
///             context.draw(cgImage, in: CGRect(x: 10, y: 10, width: Int(width), height: Int(height)))
///
///             // extract resulting image from context
///             if let image = context.makeImage() {
///                 // Write the image to disk
///                 let targetURL = URL(filePath: "SwiftDataMatrix.png", directoryHint: .notDirectory) as CFURL
///                 if let destination = CGImageDestinationCreateWithURL(targetURL,
///                                                                      UTType.png.identifier as CFString,
///                                                                      1,
///                                                                      nil) {
///                     CGImageDestinationAddImageAndMetadata(destination,
///                                                           image,
///                                                           nil,
///                                                           nil)
///                     CGImageDestinationFinalize(destination)
///                 }
///             }
///         }
///     }
/// } catch {
///     print("Failed to create SwiftDataMatrix.png due to \(error.localizedDescription)")
/// }
/// ```
///
/// - Parameter data: The data to encode in the DataMatrix code
///
/// - Parameter codeType: The kind of DataMatrix code to generate:
///                       `.default` for standard codes, `.gs1` for codes with the GS1 marker
///                       (if the data start with FNC1, code 232, that code is removed),
///                       `.readerProgramming` for codes that are used to program barcode readers.
///                       Use `.format05`/`.format06` to set the appropriate markers for the formats
///                       defined by ISO/IEC 15434. Note that in these cases, the start/end markers
///                       in the data are removed, if present.
///
/// - Parameter codeForm: DataMatrix codes can be square or rectangular. Normally, `.square` codes
///                       are created. Using `.rectangular` enforces the use of rectangular codes
///                       that are, compared to square codes, limited in the maximum amount of data
///                       they can hold. By using `.preferRectangular`, you can request to get
///                       rectangular codes when they are a better fit than the square equivalent.
///
/// - Returns The generated DataMatrix code.
///
/// - Throws A `SwiftDataMatrixError` if generation of the code fails. `SwiftDataMatrixError.outOfSpace`
///          is thrown if the amount of data cannot be encoded in the biggest available code size.
///          `SwiftDataMatrixError.invalidBlockSize` is an internal error that should never be thrown
///          (handle as if an `.outOfSpace` was thrown).
public func dataMatrix(for data: Data,
                       codeType: SwiftDataMatrixCodeType = .default,
                       codeForm: SwiftDataMatrixCodeForm = .square) throws -> SwiftDataMatrixResult {
    // Performs the high level encoding used by DataMatrix
    let encoded = try encode(data: data, codeType: codeType, codeForm: codeForm)
    
    // Split the result in blocks for ECC200 calculation
    let blocks = split(data: encoded.encodedData, junks: encoded.dataMatrixSymbolInfo.numberOfBlocks)
    
    // Calculate ECC200 data for each block
    let eccBlocks = try blocks.map { block in
        guard let ecc = ecc200(for: block, count: encoded.dataMatrixSymbolInfo.reedSolomonPerBlock)
        else { throw SwiftDataMatrixError.invalidBlockSize }
        
        return ecc
    }

    let eccData: Data
    if eccBlocks.count == 1 {
        eccData = Data(eccBlocks.first!)
    } else {
        var interleavedEcc = Data(capacity: encoded.dataMatrixSymbolInfo.numberOfBlocks * encoded.dataMatrixSymbolInfo.reedSolomonPerBlock)
        for i in 0..<encoded.dataMatrixSymbolInfo.reedSolomonPerBlock {
            for eccBlock in eccBlocks {
                interleavedEcc.append(eccBlock[eccBlock.startIndex.advanced(by: i)])
            }
        }
        eccData = interleavedEcc
    }

    let encodedWithECC = encoded.encodedData + eccData
    
    // Build the data part of the DataMatrix (without finder patterns)
    let bitstream = place(bitstream: encodedWithECC, symbolInfo: encoded.dataMatrixSymbolInfo)
    
    // Build image
    let bytesPerRow = (encoded.dataMatrixSymbolInfo.columns + 7)/8
    var image = Data(Array<UInt8>(repeating: 0xFF, count: bytesPerRow * encoded.dataMatrixSymbolInfo.rows))
    
    let dataColumns = encoded.dataMatrixSymbolInfo.columns - 2*encoded.dataMatrixSymbolInfo.regionsHorizontal
    let dataRows = encoded.dataMatrixSymbolInfo.rows - 2*encoded.dataMatrixSymbolInfo.regionsVertical
    for (i, isSet) in bitstream.enumerated() {
        if isSet {
            let y = i / dataColumns
            let x = i - y*dataColumns
            
            let horizontalRegion = x / (dataColumns / encoded.dataMatrixSymbolInfo.regionsHorizontal)
            let verticalRegion = y / (dataRows / encoded.dataMatrixSymbolInfo.regionsVertical)
            
            setPixel(in: &image, bytesPerRow: bytesPerRow, x: x + 2*horizontalRegion + 1, y: y + 2*verticalRegion + 1)
        }
    }
    
    // Draw region borders
    for y in 0..<encoded.dataMatrixSymbolInfo.rows {
        for region in 0..<encoded.dataMatrixSymbolInfo.regionsHorizontal {
            setPixel(in: &image, bytesPerRow: bytesPerRow, x: region * encoded.dataMatrixSymbolInfo.columns / encoded.dataMatrixSymbolInfo.regionsHorizontal, y: y)
            if y % 2 == 1 {
                setPixel(in: &image, bytesPerRow: bytesPerRow, x: (region+1) * encoded.dataMatrixSymbolInfo.columns / encoded.dataMatrixSymbolInfo.regionsHorizontal - 1, y: y)
            }
        }
    }
    for x in 0..<encoded.dataMatrixSymbolInfo.columns {
        for region in 0..<encoded.dataMatrixSymbolInfo.regionsVertical {
            setPixel(in: &image, bytesPerRow: bytesPerRow, x: x, y: (region+1) * encoded.dataMatrixSymbolInfo.rows / encoded.dataMatrixSymbolInfo.regionsVertical - 1)
            if x % 2 == 0 {
                setPixel(in: &image, bytesPerRow: bytesPerRow, x: x, y: region * encoded.dataMatrixSymbolInfo.rows / encoded.dataMatrixSymbolInfo.regionsVertical)
            }
        }
    }
    
    return SwiftDataMatrixResult(bitmap: image,
                                 bytesPerRow: bytesPerRow,
                                 width: encoded.dataMatrixSymbolInfo.columns,
                                 height: encoded.dataMatrixSymbolInfo.rows)
}

/// Splits the given data into several parts, sizing the parts as required for blocks by DataMatrix specification.
///
/// Part sizes are choosen in a way that makes all parts the same size if possible.
/// If the length is not evenly divisible, the excess bytes are stored in the first parts (one byte per part).
///
/// The input is distributed among the parts so that the first byte is in the first part, the second byte
/// is in the second part, and so on. For n parts, every n-th byte of the input is in a part.
///
/// - Parameter data: The data to split.
/// - Parameter junks: The number of parts to create.
/// - Returns A array of parts, sized as described.
internal func split(data: Data, junks: Int) -> [Data] {
    guard junks > 1 else { return [data] }

    var partSizes = [Int]()

    let partSize = data.count / junks
    var additional = data.count - (partSize * junks)

    for _ in 0..<junks {
        let thisPartSize: Int
        if (additional > 0) {
            thisPartSize = partSize + 1
            additional -= 1
        } else {
            thisPartSize = partSize
        }
        
        partSizes.append(thisPartSize)
    }
    
    var result = [Data]()
    for (block, partSize) in partSizes.enumerated() {
        var part = Data(capacity: partSize)
        for i in 0..<partSize {
            let offset = block + i * partSizes.count
            part.append(data[data.startIndex.advanced(by: offset)])
        }
        
        result.append(part)
    }

    return result
}

/// Sets one pixel in the image data.
///
/// Setting a pixel means its bit is reset to 0 (black).
///
/// - Parameter image: The image data to manipulate.
/// - Parameter bytesPerRow: The number of bytes one row of pixel data uses.
/// - Parameter x: The x coordinate of the pixel. (`0..<bytesPerRow*8`)
/// - Parameter y: The y coordinate of the pixes. (`0..<image.count/bytesPerRow`)
fileprivate func setPixel(in image: inout Data, bytesPerRow: Int, x: Int, y: Int) {
    let byte = x / 8 + y * bytesPerRow
    image[image.startIndex.advanced(by: byte)] &= ~(UInt8(0x0080 >> (x - ((x/8)*8))))
}


/// Places the bytes in the given data in a array of booleans that represents the image of the DataMatrix
/// code according to the symbolInfo form and size.
///
/// The returned “image” contains only the data part of the DataMatrix code, ignoring
/// any finder patterns or region splits.
///
/// - Parameter bitstream: The data to place in the “image”.
/// - Parameter symbolInfo: The specification of form and size of the DataMatrix code.
/// - Returns An array of booleans that represent the image of the data part of the DataMatrix code.
///           `true` means the pixel should be black.
fileprivate func place(bitstream: Data, symbolInfo: SymbolInfo) -> [Bool] {
    var pixels = Array<Bool?>(repeating: nil, count: symbolInfo.rows * symbolInfo.columns)
    
    let columns = symbolInfo.columns - 2*symbolInfo.regionsHorizontal
    let rows = symbolInfo.rows - 2*symbolInfo.regionsVertical
    
    // Start condition
    var pos = 0
    var row = 4
    var col = 0
    
    repeat {
        // Check for corner cases
        if row == rows && col == 0 {
            placeSpecial1(into: &pixels, columns: columns, rows: rows, value: bitstream[pos])
            pos += 1
        } else if row == rows - 2 && col == 0 && columns % 4 != 0 {
            placeSpecial2(into: &pixels, columns: columns, rows: rows, value: bitstream[pos])
            pos += 1
        } else if row == rows + 4 && col == 2 && columns % 8 == 0 {
            placeSpecial3(into: &pixels, columns: columns, rows: rows, value: bitstream[pos])
            pos += 1
        } else if row == rows - 2 && col == 0 && columns % 8 == 4 {
            placeSpecial4(into: &pixels, columns: columns, rows: rows, value: bitstream[pos])
            pos += 1
        }
        
        repeat {
            if row < rows && col >= 0 && pixels[row * columns + col] == nil {
                placeStandard(into: &pixels, columns: columns, rows: rows, x: col, y: row, value: bitstream[pos])
                pos += 1
            }
            row -= 2
            col += 2
        } while row >= 0 && col < columns
        row += 1
        col += 3
        
        repeat {
            if row >= 0 && col < columns && pixels[row * columns + col] == nil {
                placeStandard(into: &pixels, columns: columns, rows: rows, x: col, y: row, value: bitstream[pos])
                pos += 1
            }
            row += 2
            col -= 2
        } while row < rows && col >= 0
        row += 3
        col += 1
    } while row < rows || col < columns
    
    if pixels[rows * columns - 1] == nil
    {
        pixels[rows * columns - 1] = true
        pixels[(rows * columns) - columns - 2] = true
    }
    
    return pixels.map { $0 ?? false }
}

/// Places the corner type 1 form in the image.
///
///Placement:
///
/// ```
/// \.....43
/// .\.....2
/// ..\....1
/// ...\...0
/// ....\...
/// 765..\..
/// ```
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter value: The value to place.
fileprivate func placeSpecial1(into target: inout Array<Bool?>, columns: Int, rows: Int, value: UInt8) {
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 1, value: value, mask: 0x80)
    setBit(in: &target, columns: columns, rows: rows, x: 1,           y: rows - 1, value: value, mask: 0x40)
    setBit(in: &target, columns: columns, rows: rows, x: 2,           y: rows - 1, value: value, mask: 0x20)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 2, y: 0,        value: value, mask: 0x10)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 0,        value: value, mask: 0x08)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 1,        value: value, mask: 0x04)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 2,        value: value, mask: 0x02)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 3,        value: value, mask: 0x01)
}

/// Places the corner type 2 form in the image.
///
///Placement:
///
/// ```
/// \...4321
/// .\.....0
/// ..\.....
/// 7..\....
/// 6...\...
/// 5....\..
/// ```
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter value: The value to place.
fileprivate func placeSpecial2(into target: inout Array<Bool?>, columns: Int, rows: Int, value: UInt8) {
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 3, value: value, mask: 0x80)
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 2, value: value, mask: 0x40)
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 1, value: value, mask: 0x20)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 4, y: 0,        value: value, mask: 0x10)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 3, y: 0,        value: value, mask: 0x08)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 2, y: 0,        value: value, mask: 0x04)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 0,        value: value, mask: 0x02)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 1,        value: value, mask: 0x01)
}

/// Places the corner type 4 form in the image.
///
///Placement:
///
/// ```
/// \.....43
/// .\.....2
/// ..\....1
/// 7..\...0
/// 6...\...
/// 5....\..
/// ```
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter value: The value to place.
fileprivate func placeSpecial4(into target: inout Array<Bool?>, columns: Int, rows: Int, value: UInt8) {
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 3, value: value, mask: 0x80)
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 2, value: value, mask: 0x40)
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 1, value: value, mask: 0x20)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 2, y: 0,        value: value, mask: 0x10)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 0,        value: value, mask: 0x08)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 1,        value: value, mask: 0x04)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 2,        value: value, mask: 0x02)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 3,        value: value, mask: 0x01)
}


/// Places the corner type 3 form in the image.
///
///Placement:
///
/// ```
/// \....543
/// .\...210
/// ..\.....
/// ...\----
/// ...|....
/// 7..|...6
/// ```
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter value: The value to place.
fileprivate func placeSpecial3(into target: inout Array<Bool?>, columns: Int, rows: Int, value: UInt8) {
    setBit(in: &target, columns: columns, rows: rows, x: 0,           y: rows - 1, value: value, mask: 0x80)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: rows - 1, value: value, mask: 0x40)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 3, y: 0,        value: value, mask: 0x20)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 2, y: 0,        value: value, mask: 0x10)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 0,        value: value, mask: 0x08)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 3, y: 1,        value: value, mask: 0x04)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 2, y: 1,        value: value, mask: 0x02)
    setBit(in: &target, columns: columns, rows: rows, x: columns - 1, y: 1,        value: value, mask: 0x01)
}

/// Places the standard form in the image.
///
///Placement:
///
/// ```
/// 76.
/// 543
/// 210
/// ```
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter x: The x coordinate of the lowest value bit.
/// - Parameter y: Thy y coordinate of the lowest value bit.
/// - Parameter value: The value to place.
fileprivate func placeStandard(into target: inout Array<Bool?>, columns: Int, rows: Int, x: Int, y: Int, value: UInt8) {
    setBit(in: &target, columns: columns, rows: rows, x: x - 2,       y: y - 2,    value: value, mask: 0x80)
    setBit(in: &target, columns: columns, rows: rows, x: x - 1,       y: y - 2,    value: value, mask: 0x40)
    setBit(in: &target, columns: columns, rows: rows, x: x - 2,       y: y - 1,    value: value, mask: 0x20)
    setBit(in: &target, columns: columns, rows: rows, x: x - 1,       y: y - 1,    value: value, mask: 0x10)
    setBit(in: &target, columns: columns, rows: rows, x: x - 0,       y: y - 1,    value: value, mask: 0x08)
    setBit(in: &target, columns: columns, rows: rows, x: x - 2,       y: y - 0,    value: value, mask: 0x04)
    setBit(in: &target, columns: columns, rows: rows, x: x - 1,       y: y - 0,    value: value, mask: 0x02)
    setBit(in: &target, columns: columns, rows: rows, x: x - 0,       y: y - 0,    value: value, mask: 0x01)
}


/// Sets one bitt to the expected value, correcting overflowing x/y coordinates.
///
/// - Parameter target: The “image” to place the data into.
/// - Parameter columns: The width of the DataMatrix code.
/// - Parameter rows: The height of the DataMatrix code.
/// - Parameter x: The x coordinate of the bit.
/// - Parameter y: Thy y coordinate of the bit.
/// - Parameter value: The value to place.
/// - Parameter mask: The mask for the bit to look at.
fileprivate func setBit(in target: inout Array<Bool?>, columns: Int, rows: Int, x: Int, y: Int, value: UInt8, mask: UInt8) {
    var column = x
    var row = y

    if row < 0 {
        row += rows
        column += 4 - ((rows + 4) % 8)
    }
    
    if column < 0 {
        column += columns
        row += 4 - ((columns + 4) % 8)
    }
    
    target[row * columns + column] = (value & mask) != 0
}
