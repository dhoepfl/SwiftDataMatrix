//
//  TextEncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class TextEncoderTests: XCTestCase {
    func testEncodeText() throws {
        let encoded = try encode(data: "SwiftDataMatrix".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            84,             // S
            239,            // Switch to text encoding
            228, 132,       // wif
            206, 149,       // tDD
            92, 183,        // ata
            14, 151,        // MMa
            211, 47,        // tri
            254,            // Switch to ASCII
            121,            // x
            129,            // End of data
            237, 133, 28    // Padding
        ]), "Expected ASCII encoded “S”, then Text encoded rest until last char, which should be encoded in ASCII, then EOD, then padding")
    }
    
    func testEncodeTextShort() throws {
        let encoded = try encode(data: "text encoder SHOuld be used here abcdefghijklmnopqrst".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            239,            // Switch to TEXT
            209, 54,        // tex
            206, 203,       // t e
            171, 93,        // nco
            109, 48,        // der
            19, 36,         //  SS
            13, 195,        // HHO
            99, 42,         // Oul
            106, 200,       // d b
            113, 27,        // e u
            202, 226,       // sed
            22, 27,         //  he
            196, 148,       // re
            89, 233,        // abc
            109, 36,        // def
            128, 95,        // ghi
            147, 154,       // jkl
            166, 213,       // mno
            186, 16,        // pqr
            205, 41,        // st + Dummy switch to Set 1
            254,            // Switch to ASCII
            129,            // End of Data
            62, 212, 107    // Padding
        ]), "Expected the last W to be not encoded in text but to switch to ASCII")
    }
    
    func testEncodeTextOneLast() throws {
        let encoded = try encode(data: "text encoDER should be used here efghijklmnopqrstuvwabcabcabd".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            239,            // Switch to Text
            209, 54,        // tex
            206, 203,       // t e
            171, 93,        // nco
            13, 35,         // DDE
            31, 163,        // EER
            23, 214,        // R s
            180, 106,       // hou
            106, 200,       // ld
            113, 27,        // be
            202, 226,       // use
            22, 27,         // d h
            196, 148,       // re
            115, 141,       //  ef
            134, 200,       // ghi
            154, 3,         // jkl
            173, 62,        // mno
            192, 121,       // pqr
            211, 180,       // tuv
            227, 64,        // wab
            102, 64,        // cab
            102, 64,        // cab
            106             // d
        ]), "Expected the last 'd' to be encoded only using the first byte of text, leaving out the second one since it is the end of the block")
    }
    
    func testEncodeTextTwoLast() throws {
        let encoded = try encode(data: "text encoDER should be used here efghijklmnopqrstuvwAbcabcabc".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            239,            // Switch to Text
            209, 54,        // tex
            206, 203,       // t e
            171, 93,        // nco
            13, 35,         // DDE
            31, 163,        // EER
            23, 214,        // R s
            180, 106,       // hou
            106, 200,       // ld
            113, 27,        // be
            202, 226,       // use
            22, 27,         // d h
            196, 148,       // re
            115, 141,       //  ef
            134, 200,       // ghi
            154, 3,         // jkl
            173, 62,        // mno
            192, 121,       // pqr
            211, 180,       // tuv
            225, 82,        // aAA
            96, 79,         // bca
            96, 79,         // bca
            96, 65,         // bc + Dummy switch to Set 1
            254,            // Switch to ASCII
            129,            // End of Data
            198, 93, 243, 139, 34, 184, 79, 229, 124, 20, 170, 65, 215, 110, 6  // Padding
        ]), "Expected to encode the last BC as C40, then fill the second byte with a dummy switch to Set 1")
    }

    func testEncodeTextTwoLastAtEnd() throws {
        let encoded = try encode(data: "00text encoDER schould be usedAhereabca".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            130,            // 00
            239,            // Switch to text
            209, 54,        // tex
            206, 203,       // t e
            171, 93,        // nco
            13, 35,         // DDE
            31, 163,        // ERR
            23, 209,        //  sh
            135, 195,       // oul
            158, 236,       // d b
            96, 148,        // e u
            217, 147,       // sed
            106, 146,       //  AA
            134, 48,        // her
            114, 192,       // eab
            102, 49         // ca + Dummy switch to Set 1
        ]), "Expected to encode the last BC as C40, then fill the second byte with a dummy switch to Set 1")
    }

    func testEncodeTextExactMatch() throws {
        let encoded = try encode(data: "00text encoDER should be used here efghijklmnopqrstuvwAbcabca".data(using: .utf8)!)
        
        XCTAssertEqual(encoded.encodedData, Data([
            130,            // 00
            239,            // Switch to C40
            209, 54,        // tex
            206, 203,       // t e
            171, 93,        // nco
            13, 35,         // DDE
            31, 163,        // ERR
            23, 214,        //  sh
            180, 106,       // oul
            106, 200,       // d b
            113, 27,        // e u
            202, 226,       // sed
            22, 27,         //  he
            196, 148,       // re
            115, 141,       // efg
            134, 200,       // hij
            154, 3,         // klm
            173, 62,        // nop
            192, 121,       // qrs
            211, 180,       // tuv
            225, 82,        // wAA
            96, 79,         // cab
            96, 79          // cab
        ]), "Encode everything in Text, no switch back to ASCII since the block ends there.")
    }
}


