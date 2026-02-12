//
//  ECC200Tests.swift
//  SwiftDataMatrixTests
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation
import XCTest
@testable import SwiftDataMatrix

class ECC200Tests: XCTestCase {
   func testValidEcc200() {
      let ecc = ecc200(for: Data([88, 106, 108, 106, 113, 102, 101, 106, 98, 129, 251, 147]),
                       count: 12)

      XCTAssertNotNil(ecc, "Expect to get ECC data")
      XCTAssertEqual(ecc, [104, 216, 88, 39, 233, 202, 71, 217, 26, 92, 25, 232], "Expect correct ECC data")
   }

   func testInvalidEcc200() {
      let ecc = ecc200(for: Data([88, 106, 108, 106, 113, 102, 101, 106, 98, 129, 251, 147]),
                       count: 99)

      XCTAssertNil(ecc, "Expect to not get ECC data")
   }
}

