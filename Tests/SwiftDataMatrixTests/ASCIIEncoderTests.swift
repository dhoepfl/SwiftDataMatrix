//
//  ASCIIEncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-12.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class ASCIIEncoderTests: XCTestCase {
    func testNumbersEncode() throws {
        let encoded = try encode(data: "001122334455667788994242".data(using: .utf8)!)

        XCTAssertEqual(encoded.encodedData, Data([
            130, 141, 152, 163,     // 00 11 22 33  (4 * BCD)
            174, 185, 196, 207,     // 44 55 66 77  (4 * BCD)
            218, 229, 172, 172      // 88 99 42 42  (4 * BCD)
        ]), "Expected ASCII encoding using dual digit mode")
    }
}
