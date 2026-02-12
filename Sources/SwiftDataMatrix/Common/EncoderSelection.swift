//
//  EncoderSelection.swift
//  SwiftDataMatrix
//
//  Created by Daniel Höpfl on 2026-02-10.
//

import Foundation

/// Tests the characters in data to find what encoder to use for the next byte(s).
///
/// This test takes into account that switching the encoder costs space.
/// Especially for X12/EDIFACT, that cannot encode all values, switching to them is
/// suppressed if they can not encode a all values they would encounter in the next
/// encoding step. In this case, ASCII encoding is more efficient and thus used.
///
/// - Parameter data: The bytes to look at.
/// - Parameter currenctEncoder: The currently selected encoder.
/// - Returns The encoder that is assumed to be the best to be used.
internal func suggestedEncoder(data: Data, currentEncoder: EncoderType) -> EncoderType {
    let newMode = findBestNextEncoder(data: data, currentEncoder: currentEncoder)

    // X12/EDIFACT need to fall back to ASCII if they encounter a code they cannot encode
    // So it is better to use ASCII in the first place.
    if .x12 == currentEncoder && .x12 == newMode {
        let endpos = min(3, data.count)
        for i in 0..<endpos {
            if !isNativeX12(data[data.startIndex.advanced(by: i)]) {
                return .ascii
            }
        }
    } else if .edifact == currentEncoder && .edifact == newMode {
        let endpos = min(4, data.count)
        for i in 0..<endpos {
            if !isNativeEDIFACT(data[data.startIndex.advanced(by: i)]) {
                return .ascii
            }
        }
    }
    
    return newMode
}

/// Evaluates the cost of all available encoders and selects the one that is best to encode the
/// next value in data.
///
/// This function only checks streaks of equal lengths, thus it might return X12/EDIFACT because
/// it is the cheapest encoder for the next two/three characters even though it would have to
/// switch (again) for the third/fourth character. In that case ASCII would be better. This has to
/// be handled by the caller.
///
/// - Parameter data: The bytes to look at.
/// - Parameter currenctEncoder: The currently selected encoder.
/// - Returns The encoder that is assumed to be the best to be used.
fileprivate func findBestNextEncoder(data: Data, currentEncoder: EncoderType) -> EncoderType {
    if data.isEmpty {
        return currentEncoder
    }
    
    var costByEncoder: [EncoderType: Double] = [
        .ascii: 1,
        .c40: 2,
        .text: 2,
        .x12: 2,
        .edifact: 2,
        .base256: 2.25
    ]
    // Switching from ASCII is cheaper
    if .ascii == currentEncoder {
        costByEncoder = costByEncoder.mapValues({ $0 - 1 })
    }
    // Reuse current is free
    costByEncoder[currentEncoder] = 0


    var charsProcessed = 0
    while true {
        if charsProcessed == data.count {
            let evaluation = evaluate(costByEncoder: costByEncoder)
            
            if evaluation.cheapestEncoders.contains(.ascii) {
                return .ascii
            }
            if (evaluation.cheapestEncoders.count == 1) {
                if evaluation.cheapestEncoders.contains(.base256) {
                    return .base256
                }
                if evaluation.cheapestEncoders.contains(.edifact) {
                    return .edifact
                }
                if evaluation.cheapestEncoders.contains(.text) {
                    return .text
                }
                if evaluation.cheapestEncoders.contains(.x12) {
                    return .x12
                }
            }
            return .c40
        }
        
        let ch = data[data.startIndex.advanced(by: charsProcessed)]
        charsProcessed += 1

        // Price for each encoder
        
        if (isDigit(ch)) {
            costByEncoder[.ascii] = (costByEncoder[.ascii] ?? 0) + 0.5
        } else if (isExtendedASCII(ch)) {
            costByEncoder[.ascii] = ceil(costByEncoder[.ascii] ?? 0)
            costByEncoder[.ascii] = (costByEncoder[.ascii] ?? 0) + 2.0
        } else {
            costByEncoder[.ascii] = ceil(costByEncoder[.ascii] ?? 0)
            costByEncoder[.ascii] = (costByEncoder[.ascii] ?? 0) + 1.0
        }
        
        if (isNativeC40(ch)) {
            costByEncoder[.c40] = (costByEncoder[.c40] ?? 0) + 2.0 / 3.0
        } else if (isExtendedASCII(ch)) {
            costByEncoder[.c40] = (costByEncoder[.c40] ?? 0) + 8.0 / 3.0
        } else {
            costByEncoder[.c40] = (costByEncoder[.c40] ?? 0) + 4.0 / 3.0
        }
        
        if (isNativeText(ch)) {
            costByEncoder[.text] = (costByEncoder[.text] ?? 0) + 2.0 / 3.0
        } else if (isExtendedASCII(ch)) {
            costByEncoder[.text] = (costByEncoder[.text] ?? 0) + 8.0 / 3.0
        } else {
            costByEncoder[.text] = (costByEncoder[.text] ?? 0) + 4.0 / 3.0
        }
        
        if (isNativeX12(ch)) {
            costByEncoder[.x12] = (costByEncoder[.x12] ?? 0) + 2.0 / 3.0
        } else if (isExtendedASCII(ch)) {
            costByEncoder[.x12] = (costByEncoder[.x12] ?? 0) + 13.0 / 3.0
        } else {
            costByEncoder[.x12] = (costByEncoder[.x12] ?? 0) + 10.0 / 3.0
        }
        
        if (isNativeEDIFACT(ch)) {
            costByEncoder[.edifact] = (costByEncoder[.edifact] ?? 0) + 3.0 / 4.0
        } else if (isExtendedASCII(ch)) {
            costByEncoder[.edifact] = (costByEncoder[.edifact] ?? 0) + 17.0 / 4.0
        } else {
            costByEncoder[.edifact] = (costByEncoder[.edifact] ?? 0) + 13.0 / 4.0
        }
        
        costByEncoder[.base256] = (costByEncoder[.base256] ?? 0) + 1
        
        if charsProcessed >= 4 {
            let evaluation = evaluate(costByEncoder: costByEncoder)
            
            if evaluation.cost(for: .ascii) < evaluation.minCost(without: [.ascii]) {
                return .ascii
            }
            if evaluation.cost(for: .base256) < evaluation.cost(for: .ascii) ||
                (evaluation.cost(for: .base256) + 1) < evaluation.minCost(without: [.base256, .ascii]) {
                return .base256
            }
            if (evaluation.cost(for: .edifact) + 1) < evaluation.minCost(without: [.edifact]) {
                return .edifact
            }
            if (evaluation.cost(for: .text) + 1) < evaluation.minCost(without: [.text]) {
                return .text
            }
                if (evaluation.cost(for: .x12) + 1) < evaluation.minCost(without: [.x12]) {
                return .x12
            }
            if (evaluation.cost(for: .c40) + 1) < evaluation.minCost(without: [.c40, .x12]) {
                if evaluation.cost(for: .c40) < evaluation.cost(for: .x12) {
                    return .c40
                }
                if evaluation.cost(for: .c40) == evaluation.cost(for: .x12) {
                    var p = charsProcessed + 1
                    while p < data.count {
                        let tc = data[data.startIndex.advanced(by: p)]
                        if (isSpecialToX12(tc)) {
                            return .x12
                        }
                        if (!isNativeX12(tc)) {
                            break
                        }
                        p += 1
                    }
                    return .c40
                }
            }
        }
    }
}

fileprivate struct EvaluationResult {
    private let costByEncoder: [EncoderType : Int]
    let cheapestEncoders: Set<EncoderType>
    
    init(costByEncoder: [EncoderType : Int], cheapestEncoders: Set<EncoderType>) {
        self.costByEncoder = costByEncoder
        self.cheapestEncoders = cheapestEncoders
    }
    
    func cost(for encoder: EncoderType) -> Int {
        return costByEncoder[encoder] ?? Int.max
    }
    
    func minCost(without encoders: Set<EncoderType>) -> Int {
        return costByEncoder.filter({ !encoders.contains($0.key) }).reduce(Int.max, { min($0, $1.value) })
    }
}

fileprivate func evaluate(costByEncoder: [EncoderType: Double]) -> EvaluationResult {
    var roundedCostByEncoder = [EncoderType: Int]()
    var mins = Set<EncoderType>()
    
    var min = Int.max
    for i in EncoderType.allCases {
        let roundedCost = Int(ceil(costByEncoder[i] ?? 0.0))
        roundedCostByEncoder[i] = roundedCost
        
        if min > roundedCost {
            min = roundedCost
            mins = []
        }
        if min == roundedCost {
            mins.insert(i)
        }
    }
    
    return EvaluationResult(costByEncoder: roundedCostByEncoder, cheapestEncoders: mins)
}
