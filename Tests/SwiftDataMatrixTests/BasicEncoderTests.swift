//
//  BasicEncoderTests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-11.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class BasicEncoderTests: XCTestCase {
    func testSplit() {
        let data = Data([1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3, 4, 1, 2, 3])
        let splitted = split(data: data, junks: 4)

        XCTAssert(splitted.count == 4, "Expected 4 junks")
        XCTAssert(splitted[0] == Data([1, 1, 1, 1]), "Expected first junk to be correct")
        XCTAssert(splitted[1] == Data([2, 2, 2, 2]), "Expected second junk to be correct")
        XCTAssert(splitted[2] == Data([3, 3, 3, 3]), "Expected third junk to be correct")
        XCTAssert(splitted[3] == Data([4, 4, 4]), "Expected fourth junk to be correct")
    }
}


