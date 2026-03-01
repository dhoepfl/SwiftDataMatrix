//
//  EDIFACTEncoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

class EDIFACTEncoder {

    /// Encodes the next byte(s) using the EDIFACT encoding.
    ///
    /// - Parameter state: The state information to use for encoding.
    /// - Throws An `SwiftDataMatrixError` if the data cannot be encoded (too much data).
    class func encode(_ state: EncodingState) throws {
        guard state.hasMoreData else { return }

        var buffer = [UInt8]()

        repeat {
            buffer.append(state.pop())

            // If we encoded data to have 3*n output bytes, stop for now and let the outside decide how to continue
            if buffer.count % 4 == 0 {
                // write out
                
                let a = encode(ch: buffer[0])
                let b = encode(ch: buffer[1])
                let c = encode(ch: buffer[2])
                let d = encode(ch: buffer[3])

                let v = (0x040000 * a) + (0x001000 * b) + (0x000040 * c) + (0x000001 * d)
                let cw1 = UInt8(v / 0x010000)
                let cw2 = UInt8((v / 0x000100) % 256)
                let cw3 = UInt8(v % 256)

                state.append(encoded: cw1)
                state.append(encoded: cw2)
                state.append(encoded: cw3)

                buffer.removeAll()

                let nextEncoder = suggestedEncoder(state: state)
                if nextEncoder != .edifact {
                    break
                }
            }
        } while state.hasMoreData

        if state.hasMoreData || buffer.count == 3 {
            buffer.append(0)
        } else {
            let minRequiredBytes = state.encoded.count + buffer.count
            
            let dataMatrixSymbolInfo = try symbolSize(minCodeWords: minRequiredBytes, codeForm: state.codeForm)
            
            if minRequiredBytes != dataMatrixSymbolInfo.maxDataCodewords {
                buffer.append(0)
            }
        }

        // Encode remaining bytes
        
        let a = buffer.count > 0 ? encode(ch: buffer[0]) : 0
        let b = buffer.count > 1 ? encode(ch: buffer[1]) : 0
        let c = buffer.count > 2 ? encode(ch: buffer[2]) : 0
        let d = buffer.count > 3 ? encode(ch: buffer[3]) : 0

        let v = (0x040000 * a) + (0x001000 * b) + (0x000040 * c) + (0x000001 * d)
        let cw1 = UInt8(v / 0x010000)
        let cw2 = UInt8((v / 0x000100) % 256)
        let cw3 = UInt8(v % 256)

        if buffer.count > 0 {
            state.append(encoded: cw1)
        }
        if buffer.count > 1 {
            state.append(encoded: cw2)
        }
        if buffer.count > 2 {
            state.append(encoded: cw3)
        }
    }
    
    class func encode(ch: UInt8) -> UInt {
        switch ch {
        case 32...63: return UInt(ch)
        case 64...94: return UInt(ch - 64)
        default:      return UInt(31)
        }
    }
}
