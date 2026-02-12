//
//  C40Encoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

class C40Encoder {

    /// Encode a byte using the C40 encoder.
    ///
    /// - Parameter ch: The byte to encode.
    /// - Returns A `EncodedChar` that holds the original byte and the encoding sequence.
    class func encode(ch: UInt8) -> EncodedChar {
        switch ch {
            // Set 0
        case 32:            return EncodedChar(ch: ch, bytes: [3])               // Space
        case 48...57:       return EncodedChar(ch: ch, bytes: [ch - 0x30 + 4])   // 0-9
        case 65...90:       return EncodedChar(ch: ch, bytes: [ch - 65 + 14])    // A-Z
            
            // Set 1
        case 0...31:        return EncodedChar(ch: ch, bytes: [0, ch])           // Control Codes
            
            // Set 2
        case 33...47:       return EncodedChar(ch: ch, bytes: [1, ch - 33])      // !"#$%&'()*+,-./
        case 58...64:       return EncodedChar(ch: ch, bytes: [1, ch - 58 + 15]) // :;<=>?@
        case 91...95:       return EncodedChar(ch: ch, bytes: [1, ch - 91 + 22]) // [\]^_
            
            // Set 3
        case 96...127:      return EncodedChar(ch: ch, bytes: [2, ch - 96])      // `a-z{|}~DEL
            
        default:
            // Set upper bit (Set 2, hibit), then encode without upper bit set
            let withoutHighestBit = [1, 0x1e] + encode(ch: ch - 128).bytes

            return EncodedChar(ch: ch, bytes: withoutHighestBit)
        }
    }
}
