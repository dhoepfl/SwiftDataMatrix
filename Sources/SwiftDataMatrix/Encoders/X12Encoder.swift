//
//  X12Encoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-08.
//

import Foundation

class X12Encoder {
    /// Encodes the next byte(s) using the X12 encoding.
    ///
    /// - Parameter state: The state information to use for encoding.
    class func encode(_ state: EncodingState) {
        guard state.data.count >= 3 else {
            state.encoded.append(254)
            state.encoder = .ascii
            return
        }
        
        if state.data.withUnsafeBytes({ ptr in
            let a = ptr[0]
            let b = ptr[1]
            let c = ptr[2]
            
            guard isNativeX12(a) && isNativeX12(b) && isNativeX12(c) else { return false }
            
            let v = (1600 * encode(ch: a)) + (40 * encode(ch: b)) + encode(ch: c) + 1
            let cw1 = UInt8(v / 256)
            let cw2 = UInt8(v % 256)
            
            state.encoded.append(cw1)
            state.encoded.append(cw2)
            return true
        }) {
            state.data = state.data.dropFirst(3)
        }
    }

    /// Maps the code word to the X12 code value.
    ///
    /// - Parameter ch: The value to encode.
    /// - Returns The code value.
    class func encode(ch: UInt8) -> UInt {
        switch ch {
        case 13: return 0
        case 42: return 1
        case 62: return 2
        case 32: return 3
        case 0x30...0x39: return UInt(ch - 0x30 + 4)
        case 65...90: return UInt(ch - 65 + 14)
        default: return 0
        }
    }
}
