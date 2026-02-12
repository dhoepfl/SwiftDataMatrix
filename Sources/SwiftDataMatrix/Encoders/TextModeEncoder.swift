//
//  TextModeEncoder.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-06.
//

import Foundation

class TextModeEncoder {

    /// Encodes the next byte(s) using one of the Text modes for encoding.
    ///
    /// Since this encoder encodes three code words into two encoded values,
    /// care is taken that the last encoded tuple is valid. If all three values
    /// are used, the tuple is used. If two values are used, a dummy value is added
    /// to fill the tuple. If only one value is used, the first value of the tuple is
    /// used if and only if the DataMatrix code ends right after that value. Otherwise
    /// the incomplete tuple is discarded, returning the value to the data to be encoded.
    /// In that case, a forced switch to the ASCII encoder is emitted which prevents
    /// the caller from trying to encode that code word using the text mode again.
    ///
    /// - Parameter state: The state information to use for encoding.
    /// - Parameter encoder: Method used to map values to encoded data.
    /// - Throws An `SwiftDataMatrixError` if the data cannot be encoded (too much data).
    class func encode(_ state: EncodingState, encoder: (UInt8) -> EncodedChar) throws {
        guard !state.data.isEmpty else { return }

        var buffer = [EncodedChar]()
        var data = state.data

        repeat {
            let ch = data.first!
            buffer.append(encoder(ch))
            data = data.advanced(by: 1)

            // If we encoded data to have 3*n output bytes, stop for now and let the outside decide how to continue
            let bytesToWrite = buffer.reduce(0) { $0 + $1.bytes.count }
            if bytesToWrite % 3 == 0 {
                let nextEncoder = suggestedEncoder(data: data, currentEncoder: state.encoder)
                if nextEncoder != state.encoder {
                    break
                }
            }
        } while !data.isEmpty
        
        guard !buffer.isEmpty else { return }

        // If buffer contains anything but 3*n characters, we reached end of data.

        // Drop encodable characters to prevent 1 byte in the last C40 (unless this matches max count)
        let countAfterEncoding = {
            let count = buffer.reduce(0) { $0 + $1.bytes.count }
            if count % 3 == 0 {
                return count * 2 / 3
            } else if count % 3 == 1 {
                return (count / 3) * 2 + 1
            } else {
                return (count / 3) * 2 + 2
            }
        }() + state.encoded.count 
        let symbolInfo = try symbolSize(minCodeWords: countAfterEncoding, codeForm: state.codeForm)

        var forceSwitchToAscii = false
        if symbolInfo.maxDataCodewords > countAfterEncoding {
            while (buffer.reduce(0) { $0 + $1.bytes.count }) % 3 == 1 {
                data.insert(buffer.last!.ch, at: data.startIndex)
                buffer = buffer.dropLast()
                forceSwitchToAscii = true
            }
        }
        
        // Here we have 3*n+1 (equal to max codewords) or 3*n or 3*n+2 bytes to encode
        
        // For the 3*n+2 case, we add a dummy switch to Set 1
        if (buffer.reduce(0) { $0 + $1.bytes.count }) % 3 == 2 {
            buffer.append(EncodedChar(ch: 0, bytes: [0]))
        }

        let c40Data = buffer.reduce([UInt8]()) { $0 + $1.bytes }
        
        for i in stride(from: 0, to: c40Data.count, by: 3) {
            let a = UInt(c40Data[i+0])
            let b = c40Data.count > i+1 ? UInt(c40Data[i+1]) : 0
            let c = c40Data.count > i+2 ? UInt(c40Data[i+2]) : 0
            
            let v = (1600 * a) + (40 * b) + c + 1
            let cw1 = UInt8(v / 256)
            let cw2 = UInt8(v % 256)
            
            state.encoded.append(cw1)
            if c40Data.count > i+1 {
                state.encoded.append(cw2)
            }
        }

        state.data = data
        
        if forceSwitchToAscii {
            state.encoded.append(254)
            state.encoder = .ascii
        }
    }
}
