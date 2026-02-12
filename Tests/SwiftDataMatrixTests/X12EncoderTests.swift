//
//  C12EncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class C12EncoderTests: XCTestCase {
    func testEncodeX12() throws {
        let encoded = try encode(data: "***X12 SHOULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVW".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            238,        // Switch to X12
            6, 106,     // ***
            232, 15,    // X12
            23, 214,    //  SH
            180, 106,   // OUL
            106, 200,   // D B
            113, 27,    // E U
            202, 226,   // SED
            22, 27,     //  HE
            196, 148,   // RE
            89, 233,    // ABC
            109, 36,    // DEF
            128, 95,    // GHI
            147, 154,   // JKL
            166, 213,   // MNO
            186, 16,    // PQR
            205, 75,    // STU
            254,        // Switch to ASCII
            87, 88      // VW
        ]), "Expected correct data")
    }
}
