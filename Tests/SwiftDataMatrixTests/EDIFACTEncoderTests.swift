//
//  EDIFACTEncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class EDIFACTEncoderTests: XCTestCase {
    func testEncodeEDIFACT() throws {
        let encoded = try encode(data: "@@@@@@EDIFACT SHOULD BE USED HERE".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            240,            // Switch to EDIFACT
            0,   0,   0,    // @@@@
            0,   1,  68,    // @@ED
            36,  96,  67,   // IFAC
            82,   4, 200,   // T SH
            61,  83,   4,   // OULD
            128,  33, 96,   //  BE
            85,  49,  68,   // USED
            128, 129,  82,  //  HER
            21, 240,        // E, Switch to ASCII
            129, 150,  45   // End of data, padding
        ]), "Expected EDIFACT data until less than 4 chars left, then switch to ASCII and padding")
    }
    
    func testEncodeEDIFACTSwitchToAscii() throws {
        let encoded = try encode(data: "@@@@@@EDIFACT SHOULD BE USED HEREABC".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            240,            // Switch to EDIFACT
            0,   0,   0,    // @@@@
            0,   1,  68,    // @@ED
            36,  96,  67,   // IFAC
            82,   4, 200,   // T SH
            61,  83,   4,   // OULD
            128,  33, 96,   //  BE
            85,  49,  68,   // USED
            128, 129, 82,   //  HER
            20, 16, 131,    // EABC
            124,            // Switch to ASCII
            129             // End of Data
        ]), "Expected EDIFACT data until less than 4 chars left, then switch to ASCII and padding")
    }

    func testEncodeEDIFACTNoSwitchToAscii() throws {
        let encoded = try encode(data: "@@@@@@EDIFACT SHOULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVW".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            240,            // Switch to EDIFACT
            0,   0,   0,    // @@@@
            0,   1,  68,    // @@ED
            36,  96,  67,   // IFAC
            82,   4, 200,   // T SH
            61,  83,   4,   // OULD
            128,  33, 96,   //  BE
            85,  49,  68,   // USED
            128, 129,  82,  //  HER
            22, 0, 66,      // E AB
            12, 65, 70,     // CDEF
            28, 130, 74,    // GHIJ
            44, 195, 78,    // KLMN
            61, 4, 82,      // OPQR
            77, 69, 86,     // STUV
            92              // W
        ]), "Expected correct data")
    }
}
