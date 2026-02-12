//
//  SwiftDataMatrixTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class SwiftDataMatrixTests: XCTestCase {
    func testDataMatrixCreation() throws {
        let testContent = "This DataMatrix code should be 24x24 elements"
        let datamatrix = try dataMatrix(for: testContent.data(using: .utf8)!)

        printResult(testContent, datamatrix)

        XCTAssertEqual(datamatrix.width, 24, "Expected code width 24 (and square code)")
        XCTAssertEqual(datamatrix.height, 24, "Expected code height 24 (and square code)")
        XCTAssertEqual(datamatrix.bytesPerRow, 3, "Expected minimal bytes per row")
        XCTAssertEqual(datamatrix.bitmap, Data([
            85,  85,  85,   6, 152, 142,  47,  55,  67,  11, 129,  80, 120, 184,  99,
            40,  46, 204,  21,   2,  93,  12, 172, 234, 117,  49, 215,  96, 160, 142,
            105, 229,  41,  21, 203, 196, 106, 126, 171,  17,  65,  42,  46, 245,   1,
            88, 135,  24, 103, 200, 141,   0, 229,  54,   2,  45,   7,   8, 164, 138,
            88, 173, 251,  50, 129, 178,  55,  62,  77,   0,   0,   0
        ]), "Expected correctly encoded DataMatrix code image")
    }

    func testDataGS1MatrixCreation() throws {
        let testContent = "This DataMatrix code should be 24x24 elements"
        let datamatrix = try dataMatrix(for: testContent.data(using: .utf8)!, codeType: .gs1)

        printResult(testContent, datamatrix)

        XCTAssertEqual(datamatrix.width, 24, "Expected code width 24 (and square code)")
        XCTAssertEqual(datamatrix.height, 24, "Expected code height 24 (and square code)")
        XCTAssertEqual(datamatrix.bytesPerRow, 3, "Expected minimal bytes per row")
        XCTAssertEqual(datamatrix.bitmap, Data([
            85,  85,  85,  67, 227,  86,  80, 167,  19,  42,   3, 184,  61,  92, 139,
            107,   3,   0, 101, 228, 139,  56, 168,  38,  88,  25, 115,  38, 243, 158,
            20, 159,  49,   2,  86, 120,  39, 167, 121,  86,  38, 228,  41,  98,   5,
            64,  89, 162,  35,  18, 207,  65, 148,  40,  28, 242, 231, 124, 150,  22,
            1, 188,  43,  25, 128, 250,  98, 115,  37,   0,   0,   0
        ]), "Expected correctly encoded DataMatrix code image")
    }

    func testDataMatrixCreationRectangular() throws {
        let testContent = "This DataMatrix code should be 48x16 elements"
        let datamatrix = try dataMatrix(for: testContent.data(using: .utf8)!, codeForm: .rectangular)

        printResult(testContent, datamatrix)

        XCTAssertEqual(datamatrix.width, 48, "Expected code width 48 (and rectangular code)")
        XCTAssertEqual(datamatrix.height, 16, "Expected code height 16 (and rectangular code)")
        XCTAssertEqual(datamatrix.bytesPerRow, 6, "Expected minimal bytes per row")
        XCTAssertEqual(datamatrix.bitmap, Data([
            85,  85,  85,  85,  85,  85,   6, 152, 196,  84,  73,  26,
            47,  55,  92, 111,  74,  13,  11, 129, 252, 186,  42,  12,
            120, 185, 216,  93, 242,  13,  40,  45, 162, 158,  87, 204,
            21,   1, 199, 193, 163, 245,   0,   0,   0,   0,   0,   0,
            85,  85,  85,  85,  85,  85,  12, 166,  86,  15, 226,  42,
            117,  58, 132,  51, 152,  79,  96, 220, 142, 250,  40, 166,
            105, 161, 137, 254, 251, 189,  20, 216,  20,  66,  49, 152,
            43, 203, 153, 190, 225, 153,   0,   0,   0,   0,   0,   0,
        ]), "Expected correctly encoded DataMatrix code image")
    }

    func testDataMatrixCreationPreferingRectangular() throws {
        let testContent = "26x12 RectAcB0000"
        let datamatrix = try dataMatrix(for: testContent.data(using: .utf8)!, codeForm: .preferRectangular)

        printResult(testContent, datamatrix)

        XCTAssertEqual(datamatrix.width, 26, "Expected code width 26 (and rectangular code)")
        XCTAssertEqual(datamatrix.height, 12, "Expected code height 12 (and rectangular code)")
        XCTAssertEqual(datamatrix.bytesPerRow, 4, "Expected minimal bytes per row")
        XCTAssertEqual(datamatrix.bitmap, Data([
            85,  85,  85, 127,  69, 215, 180,  63,  11, 118, 186, 127,
            107,  78,  82, 191,  40, 236, 183, 127,  92, 239, 128, 191,
            15,   6,  87, 255, 117,  67,  24,  63, 100,  80, 224, 127,
            41, 170, 232,  63, 109, 118,  25, 127,   0,   0,   0,  63
        ]), "Expected correctly encoded DataMatrix code image")
    }

    func testDataMatrixCreationPreferingRectangularButSquareIsBetter() throws {
        let testContent = "This DataMatrix code should be 24x24 elements"
        let datamatrix = try dataMatrix(for: testContent.data(using: .utf8)!, codeForm: .preferRectangular)

        printResult(testContent, datamatrix)

        XCTAssertEqual(datamatrix.width, 24, "Expected code width 24 (and square code)")
        XCTAssertEqual(datamatrix.height, 24, "Expected code height 24 (and square code)")
        XCTAssertEqual(datamatrix.bytesPerRow, 3, "Expected minimal bytes per row")
        XCTAssertEqual(datamatrix.bitmap, Data([
            85,  85,  85,   6, 152, 142,  47,  55,  67,  11, 129,  80, 120, 184,  99,
            40,  46, 204,  21,   2,  93,  12, 172, 234, 117,  49, 215,  96, 160, 142,
            105, 229,  41,  21, 203, 196, 106, 126, 171,  17,  65,  42,  46, 245,   1,
            88, 135,  24, 103, 200, 141,   0, 229,  54,   2,  45,   7,   8, 164, 138,
            88, 173, 251,  50, 129, 178,  55,  62,  77,   0,   0,   0
        ]), "Expected correctly encoded DataMatrix code image")
    }

    private func printResult(_ data: String, _ result: SwiftDataMatrixResult) {
        print("Encoded: “\(data)”")
        print("Result size: \(result.width)x\(result.height), bytes per row: \(result.bytesPerRow)")

        // Dump as text
        var imageString = ""
        for (i, byte) in result.bitmap.enumerated() {
            let row = i / result.bytesPerRow
            let byteInRow = i - row * result.bytesPerRow

            if byteInRow == 0 {
                imageString += "\n"
            }

            for bit in 0...7 {
                let x = byteInRow * 8 + bit

                if x < result.width {
                    let mask = UInt8(1 << (7 - bit))

                    if (byte & mask) == 0 {
                        imageString += "\u{2588}\u{2588}"
                    } else {
                        imageString += "  "
                    }
                } else {
                    imageString += "."
                }
            }
        }
        print(imageString)
    }
}
