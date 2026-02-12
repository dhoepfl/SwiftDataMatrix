//
//  EncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class EncoderTests: XCTestCase {
    func testEncodeGS1() throws {
        let encoded = try encode(data: "01012345678901281730033110A12W123\u{1d}21X12345678".data(using: .utf8)!, codeType: .gs1)
        
        XCTAssertEqual(encoded.encodedData, Data([
            232,            // GS1 marker
            131, 131, 153,  // 01 01 23     (3 * BCD)
            175, 197, 219,  // 45 67 89     (3 * BCD)
            131, 158, 147,  // 01 28 17     (3 * BCD)
            160, 133, 161,  // 30 03 31     (3 * BCD)
            140,  66, 142,  // 10 A  12     (BCD, ASCII, BCD)
             88, 142,  52,  // W  12  3     (ASCII, BCD, ASCII)
             30, 151,  89,  // GS 21  X     (ASCII, BCD, ASCII)
            142, 164, 186,  // 12 34 56     (3 * BCD)
            208,            // 78           (BCD)
            129,            // End of data
            254, 150,  45   // Padding
        ]), "Expected correct data")
    }
    
    func testEncodeGS1FNC1Prefix() throws {
        let encoded = try encode(data: [232] + ("01012345678901281730033110A12W123\u{1d}21X12345678".data(using: .utf8)!), codeType: .gs1)
        
        XCTAssertEqual(encoded.encodedData, Data([
            232,            // GS1 marker
            131, 131, 153,  // 01 01 23     (3 * BCD)
            175, 197, 219,  // 45 67 89     (3 * BCD)
            131, 158, 147,  // 01 28 17     (3 * BCD)
            160, 133, 161,  // 30 03 31     (3 * BCD)
            140,  66, 142,  // 10 A  12     (BCD, ASCII, BCD)
            88, 142,  52,  // W  12  3     (ASCII, BCD, ASCII)
            30, 151,  89,  // GS 21  X     (ASCII, BCD, ASCII)
            142, 164, 186,  // 12 34 56     (3 * BCD)
            208,            // 78           (BCD)
            129,            // End of data
            254, 150,  45   // Padding
        ]), "Expected correct data")
    }
    
    func testEncodeFormat05() throws {
        let encoded = try encode(data: "[)>\u{001E}05\u{001D}content\u{001E}\u{0004}".data(using: .utf8)!, codeType: .format05)
        
        XCTAssertEqual(encoded.encodedData, Data([
            236,            // Macro 05 marker
            239,            // Switch to text encoding
            104, 124,       // con
            209, 44,        // ten
            254,            // Switch to ASCII
            117             // ASCII "t"
        ]), "Expected correct data")
    }
    
    func testEncodeFormat06() throws {
        let encoded = try encode(data: "[)>\u{001E}06\u{001D}content\u{001E}\u{0004}".data(using: .utf8)!, codeType: .format06)
        
        XCTAssertEqual(encoded.encodedData, Data([
            237,            // Macro 06 marker
            239,            // Switch to text encoding
            104, 124,       // con
            209, 44,        // ten
            254,            // Switch to ASCII
            117             // ASCII "t"
        ]), "Expected correct data")
    }
        
    func testEncodeFormat05NoMarker() throws {
        let encoded = try encode(data: "content".data(using: .utf8)!, codeType: .format05)
        
        XCTAssertEqual(encoded.encodedData, Data([
            236,            // Macro 05 marker
            239,            // Switch to text encoding
            104, 124,       // con
            209, 44,        // ten
            254,            // Switch to ASCII
            117             // ASCII "t"
        ]), "Expected correct data")
    }
    
    func testEncodeFormat06NoMarker() throws {
        let encoded = try encode(data: "content".data(using: .utf8)!, codeType: .format06)
        
        XCTAssertEqual(encoded.encodedData, Data([
            237,            // Macro 06 marker
            239,            // Switch to text encoding
            104, 124,       // con
            209, 44,        // ten
            254,            // Switch to ASCII
            117             // ASCII "t"
        ]), "Expected correct data")
    }
}
