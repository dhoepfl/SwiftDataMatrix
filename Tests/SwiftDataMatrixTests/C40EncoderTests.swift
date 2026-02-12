//
//  C40EncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class C40EncoderTests: XCTestCase {
    func testEncodeC40Short() throws {
        let encoded = try encode(data: "C FOURTY shoULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVW".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            230,                // Switch to C40
            100, 140,           // C F
            180, 112,           // OUR
            212, 52,            // TY
            15, 123,            // ssh
            50, 96,             // hoo
            216, 122,           // ULD
            21, 43,             //  BE
            24, 49,             //  US
            115, 44,            // ED
            134, 48,            // HER
            113, 7,             // E A
            96, 82,             // BCD
            115, 141,           // EFG
            134, 200,           // HIJ
            154, 3,             // KLM
            173, 62,            // NOP
            192, 121,           // QRS
            211, 180,           // TUV
            254,                // Switch to ASCII
            88,                 // W
            129,                // End of Message
            167, 62, 212, 107   // Padding
        ]), "Expected the last W to be not encoded in C40 but to switch to ASCII")
    }
    
    func testEncodeC40OneLast() throws {
        let encoded = try encode(data: "C FOURTY shoULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVWABCABCABC".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            230,            // Switch to C40
            100, 140,       // C F
            180, 112,       // OUR
            212, 52,        // TY
            15, 123,        // ssh
            50, 96,         // hoo
            216, 122,       // ULD
            21, 43,         //  BE
            24, 49,         //  US
            115, 44,        // ED
            134, 48,        // HER
            113, 7,         // E A
            96, 82,         // BCD
            115, 141,       // EFG
            134, 200,       // HIJ
            154, 3,         // KLM
            173, 62,        // NOP
            192, 121,       // QRS
            211, 180,       // TUV
            227, 64,        // WAB
            102, 64,        // CAB
            102, 64,        // CAB
            100,            // C
        ]), "Expected the last C to be encoded only using the first byte of C40, leaving out the second one since it is the end of the block")
    }
    
    func testEncodeC40TwoLast() throws {
        let encoded = try encode(data: "C FOURTY shoULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVWaBCABCABC".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            230,            // Switch to C40
            100, 140,       // C F
            180, 112,       // OUR
            212, 52,        // TY
            15, 123,        // ssh
            50, 96,         // hoo
            216, 122,       // ULD
            21, 43,         //  BE
            24, 49,         //  US
            115, 44,        // ED
            134, 48,        // HER
            113, 7,         // E A
            96, 82,         // BCD
            115, 141,       // EFG
            134, 200,       // HIJ
            154, 3,         // KLM
            173, 62,        // NOP
            192, 121,       // QRS
            211, 180,       // TUV
            225, 82,        // Waa
            96, 79,         // BCA
            96, 79,         // BCA
            96, 65,         // BC + Dummy switch to Set 1
            254,            // Switch to ASCII
            129,            // End of Data
            198, 93, 243, 139, 34, 184, 79, 229, 124, 20, 170, 65, 215, 110, 6      // Padding
        ]), "Expected to encode the last BC as C40, then fill the second byte with a dummy switch to Set 1")
    }

    func testEncodeC40TwoLastAtEnd() throws {
        let encoded = try encode(data: "00C FOURTY shoULD BE USED HERWaBCABCABC".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            130,            // 00
            230,            // Switch to C40
            100, 140,       // C F
            180, 112,       // OUR
            212, 52,        // TY
            15, 123,        // ssh
            50, 96,         // hoo
            216, 122,       // ULD
            21, 43,         //  BE
            24, 49,         //  US
            115, 44,        // ED
            134, 48,        // HER
            225, 82,        // Waa
            96, 79,         // BCA
            96, 79,         // BCA
            96, 65,         // BC + Dummy switch to Set 1
        ]), "Expected to encode the last BC as C40, then fill the second byte with a dummy switch to Set 1")
    }

    func testEncodeC40ExactMatch() throws {
        let encoded = try encode(data: "00C FOURTY shoULD BE USED HERE ABCDEFGHIJKLMNOPQRSTUVWaBCABCA".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            130,            // 00
            230,            // Switch to C40
            100, 140,       // C F
            180, 112,       // OUR
            212, 52,        // TY
            15, 123,        // ssh
            50, 96,         // hoo
            216, 122,       // ULD
            21, 43,         //  BE
            24, 49,         //  US
            115, 44,        // ED
            134, 48,        // HER
            113, 7,         // E A
            96, 82,         // BCD
            115, 141,       // EFG
            134, 200,       // HIJ
            154, 3,         // KLM
            173, 62,        // NOP
            192, 121,       // QRS
            211, 180,       // TUV
            225, 82,        // Waa
            96, 79,         // BCA
            96, 79,         // BCA
        ]), "Encode everything in C40, no switch back to ASCII since the block ends there.")
    }
}
