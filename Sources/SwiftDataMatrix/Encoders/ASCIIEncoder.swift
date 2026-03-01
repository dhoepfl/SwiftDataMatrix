//
//  ASCIIEncoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

/// Encodes data in the “ASCII encoding” form.
class ASCIIEncoder {

    /// Encodes the next byte(s) using the ASCII encoding.
    ///
    /// - Parameter state: The state information to use for encoding.
    class func encode(_ state: EncodingState) {
        // Encode groups of 2 digits
        if state.pendingDataCount >= 2 &&
            state.peek() >= 0x30 && state.peek() <= 0x39 &&
            state.peek(skipping: 1) >= 0x30 && state.peek(skipping: 1) <= 0x39 {
            let a = state.pop()
            let b = state.pop()
            state.append(encoded: (a-0x30)*10+(b-0x30)+130)
        } else if isExtendedASCII(state.peek()) {
            state.append(encoded: 235)
            state.append(encoded: state.pop()-128+1)
        } else {
            state.append(encoded: state.pop()+1)
        }
    }
}
