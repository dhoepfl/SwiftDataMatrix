//
//  Base256Encoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

class Base256Encoder {

    /// Encodes the next byte(s) using the Base256 encoding.
    ///
    /// - Parameter state: The state information to use for encoding.
    /// - Throws An `SwiftDataMatrixError` if the data cannot be encoded (too much data).
    class func encode(_ state: EncodingState) throws {
        guard state.hasMoreData else { return }

        var dataToEncode = [UInt8]()
        repeat {
            dataToEncode.append(state.pop())

            let nextEncoder = suggestedEncoder(state: state)
            if nextEncoder != .base256 {
                break
            }
        } while state.hasMoreData

        let length = dataToEncode.count
        guard length/250 <= 6 else { throw SwiftDataMatrixError.outOfSpace }

        if length <= 254 {
            state.append(encoded: randomize(UInt8(length), n: state.encoded.count))
        } else {
            state.append(encoded: randomize(UInt8(length/250 + 249), n: state.encoded.count))
            state.append(encoded: randomize(UInt8(length % 250), n: state.encoded.count))
        }
        
        for ch in dataToEncode {
            state.append(encoded: randomize(ch, n: state.encoded.count))
        }
    }

    /// Creates a pseudo random number and modifies the value using it to
    /// avoid sequences of equal values in common data.
    ///
    /// - Parameter ch: The value to modify.
    /// - Parameter n: The position in the output stream.
    /// - Returns The modified value.
    class func randomize(_ ch: UInt8, n: Int) -> UInt8 {
        let r = (n * 149) % 254 + 1
        let s = r + Int(ch)
        return UInt8(s % 256)
    }
}
