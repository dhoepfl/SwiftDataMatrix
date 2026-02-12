//
//  Base256EncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class Base256EncoderTests: XCTestCase {    
    func testEncodeBase256() throws {
        let encoded = try encode(data: Data([130, 140, 150, 170, 180, 190, 200, 210, 220]))
        
        XCTAssertEqual(encoded.encodedData, Data([
            231,            // Switch to base256
            159,            // Length (9) + 150 (Pseudo Random), modulo 256
            175,            // 130 +  45 (PR), modulo 256
            78,             // 140 + 194 (PR), modulo 256
            239,            // 150 +  89 (PR), modulo 256
            152,            // 170 + 238 (PR), modulo 256
            57,             // 180 + 133 (PR), modulo 256
            218,            // 190 +  28 (PR), modulo 256
            121,            // 200 + 177 (PR), modulo 256
            26,             // 210 +  72 (PR), modulo 256
            185,            // 220 + 221 (PR), modulo 256
            129,            // Padding
        ]), "Expected correctly encoded base 256 data")
    }
}
