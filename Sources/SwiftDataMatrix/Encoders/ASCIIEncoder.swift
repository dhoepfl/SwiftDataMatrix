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
        if state.data.count >= 2 &&
            state.data.withUnsafeBytes({ ptr in
                if ptr[0] >= 0x30 && ptr[0] <= 0x39 &&
                    ptr[1] >= 0x30 && ptr[1] <= 0x39 {
                    state.encoded.append((ptr[0]-0x30)*10+(ptr[1]-0x30)+130)
                    return true
                }
                
                return false
            }) {
            state.data = state.data.dropFirst(2)
        } else if isExtendedASCII(state.data.first!) {
            state.encoded.append(235)
            state.encoded.append(state.data.first!-128+1)
            state.data = state.data.dropFirst()
        } else {
            state.encoded.append(state.data.first!+1)
            state.data = state.data.dropFirst()
        }
    }
}
