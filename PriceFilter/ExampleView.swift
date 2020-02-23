//
//  ExampleView.swift
//  PriceFilter
//
//  Created by Roman Kyrylenko on 23.02.2020.
//  Copyright © 2020 Roman Kyrylenko. All rights reserved.
//

import SwiftUI

struct SliderView_Previews: PreviewProvider {
    
    static var previews: some View {
        ExampleView()
    }
}

struct ExampleView: View {
    
    static let valueFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        
        return formatter
    }()
    
    @ObservedObject var viewModel = SliderViewModel()
    
    var body: some View {
        VStack {
            SliderView(viewModel: viewModel)
                .frame(width: 300, height: 300)
            Text("From \(Self.valueFormatter.string(for: viewModel.fromPrice)!) to \(Self.valueFormatter.string(for: viewModel.toPrice)!)")
        }
    }
}
