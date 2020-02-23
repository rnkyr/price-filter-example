//
//  SliderViewModel.swift
//  PriceFilter
//
//  Created by Roman Kyrylenko on 21.02.2020.
//  Copyright © 2020 Roman Kyrylenko. All rights reserved.
//

import SwiftUI
import Combine

final class SliderViewModel: ObservableObject {
    
    @Published var fromPrice: CGFloat
    @Published var toPrice: CGFloat
    
    @Published var fromValue: CGFloat
    @Published var toValue: CGFloat
    @Published var sortedPrices: [(ClosedRange<Int>, Int)]
    
    private var disposables = Set<AnyCancellable>()
    
    init(
        prices: [ClosedRange<Int>: Int] = [
            (0...1): 500, (1...2): 1000, (2...3): 1500, (3...4): 1700, (4...5): 1850, (5...6): 2300,
            (6...7): 2000, (7...8): 1725, (8...9): 1200, (9...10): 750, (10...11): 2000, (11...12): 1725, (12...13): 1200, (13...14): 750
        ],
        fromPrice: CGFloat = 4.5,
        toPrice: CGFloat = 10.75
    ) {
        fromValue = 0
        toValue = 1
        sortedPrices = SliderViewModel.sort(prices)
        self.fromPrice = fromPrice
        self.toPrice = toPrice
        
        guard let lowerBound = sortedPrices.first?.0.lowerBound,
            let upperBound = sortedPrices.last?.0.upperBound else {
                return
        }
        
        fromValue = fromPrice / CGFloat(upperBound - lowerBound)
        toValue = toPrice / CGFloat(upperBound - lowerBound)
        
        Publishers
            .CombineLatest($fromValue, $sortedPrices)
            .map { value, prices in
                guard let lowerBound = prices.first?.0.lowerBound,
                    let upperBound = prices.last?.0.upperBound else {
                        return value
                }
                
                return value * CGFloat(lowerBound + (upperBound - lowerBound))
            }
            .assign(to: \.fromPrice, on: self)
            .store(in: &disposables)
        
        Publishers
            .CombineLatest($toValue, $sortedPrices)
            .map { value, prices in
                guard let lowerBound = prices.first?.0.lowerBound,
                    let upperBound = prices.last?.0.upperBound else {
                        return value
                }
                
                return value * CGFloat(lowerBound + (upperBound - lowerBound))
            }
            .assign(to: \.toPrice, on: self)
            .store(in: &disposables)
    }
    
    private static func sort(_ prices: [ClosedRange<Int>: Int]) -> [(ClosedRange<Int>, Int)] {
        var sortedPrices = prices.sorted { lhs, rhs -> Bool in
            lhs.key.lowerBound < rhs.key.lowerBound
        }
        var previousRange: ClosedRange<Int>!
        var mutated = false
        sortedPrices.forEach { range, _ in
            if previousRange == nil {
                previousRange = range
                
                return
            }
            
            if range.lowerBound != previousRange.upperBound {
                // in case some range missed fill it in with zero value
                sortedPrices.append((previousRange.upperBound...range.lowerBound, 0))
                mutated = true
            }
            previousRange = range
        }
        if mutated {
            return sortedPrices.sorted { lhs, rhs -> Bool in
                lhs.key.lowerBound < rhs.key.lowerBound
            }
        } else {
            return sortedPrices
        }
    }
}
