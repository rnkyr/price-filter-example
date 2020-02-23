//
//  ContentView.swift
//  PriceFilter
//
//  Created by Roman Kyrylenko on 17.02.2020.
//  Copyright © 2020 Roman Kyrylenko. All rights reserved.
//

import SwiftUI

struct SliderView: View {
    
    @ObservedObject var viewModel: SliderViewModel
    
    let thumbSize: CGFloat = 25.0
    let progressLineHeight: CGFloat = 3.0
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                graphView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding([.leading, .trailing, .bottom], thumbSize / 2)
            }
            VStack {
                Spacer()
                progressLineView()
                    .frame(height: progressLineHeight)
                    .padding(.bottom, (thumbSize - progressLineHeight) / 2)
            }
            VStack {
                Spacer()
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        self.thumbsView(geometry: geometry)
                        Spacer()
                    }
                }
                .frame(height: thumbSize)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func thumbsView(geometry: GeometryProxy) -> some View {
        ZStack {
            ThumbView(
                thumbSize: self.thumbSize,
                superViewWidth: geometry.frame(in: .global).width,
                progress: self.$viewModel.fromValue,
                limitedToProgress: self.viewModel.toValue,
                limitedToBelow: true
            )
            ThumbView(
                thumbSize: self.thumbSize,
                superViewWidth: geometry.frame(in: .global).width,
                progress: self.$viewModel.toValue,
                limitedToProgress: self.viewModel.fromValue,
                limitedToBelow: false
            )
        }
    }
    
    private func graphView() -> some View {
        GraphView(
            leftProgress: $viewModel.fromValue,
            rightProgress: $viewModel.toValue,
            sortedPrices: $viewModel.sortedPrices,
            thumbSize: thumbSize
        )
    }
    
    private func progressLineView() -> some View {
        ProgressLineView(
            leftProgress: $viewModel.fromValue,
            rightProgress: $viewModel.toValue
        )
    }
}

private struct ThumbView: View {
    
    let thumbSize: CGFloat
    let superViewWidth: CGFloat
    @Binding var progress: CGFloat
    let limitedToProgress: CGFloat
    let limitedToBelow: Bool
    
    let thumbColor = Color.white
    let thumbShadowColor = Color(red: 12 / 255, green: 24 / 255, blue: 35 / 255, opacity: 0.35)
    let progressLimit: CGFloat = 0.025
    
    var body: some View {
        Circle()
            .fill(thumbColor)
            .frame(width: thumbSize)
            .shadow(color: thumbShadowColor, radius: 3, x: 0, y: 1)
            .offset(x: progress * (superViewWidth - thumbSize), y: 0)
            .gesture(
                DragGesture().onChanged { value in
                    self.updateProgress(with: value.location)
                }
            )
    }
    
    private func updateProgress(with location: CGPoint) {
        var position = location.x - thumbSize / 2
        position = max(0, min(superViewWidth - thumbSize, position))
        
        let progress = ((position / (superViewWidth - thumbSize)) * 100).rounded() / 100
        if limitedToBelow && progress < (limitedToProgress - progressLimit)
            || !limitedToBelow && progress > (limitedToProgress + progressLimit) {
            self.progress = progress
        }
    }
}

private struct ProgressLineView: View {
    
    @Binding var leftProgress: CGFloat
    @Binding var rightProgress: CGFloat
    
    let emptyLineColor = Color(red: 230 / 255, green: 231 / 255, blue: 232 / 255)
    let filledLineColor = Color(red: 255 / 255, green: 64 / 255, blue: 105 / 255)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.emptyLeftLine.frame(width: self.leftProgress * geometry.frame(in: .global).width)
                self.filledLine.frame(width: (self.rightProgress - self.leftProgress) * geometry.frame(in: .global).width)
                self.emptyRightLine
            }
        }
    }
    
    private var emptyLeftLine: some View {
        Rectangle()
            .fill(emptyLineColor)
            .cornerRadius(2)
    }
    private var emptyRightLine: some View {
        Rectangle()
            .fill(emptyLineColor)
            .cornerRadius(2)
    }
    private var filledLine: some View {
        Rectangle()
            .fill(filledLineColor)
            .cornerRadius(2)
    }
}

private struct GraphView: View {
    
    @Binding var leftProgress: CGFloat
    @Binding var rightProgress: CGFloat
    @Binding var sortedPrices: [(ClosedRange<Int>, Int)]
    let thumbSize: CGFloat
    
    let emptyGraphColor = Color(red: 230 / 255, green: 231 / 255, blue: 232 / 255)
    let filledGraphColor = Color(red: 255 / 255, green: 142 / 255, blue: 156 / 255)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                self.emptyLeftView.frame(width: self.leftProgress * (geometry.frame(in: .global).width))
                self.filledView.frame(width: (self.rightProgress - self.leftProgress) * (geometry.frame(in: .global).width))
                self.emptyRightView
            }
            .mask(self.maskView(geometry))
        }
    }
    
    private var emptyLeftView: some View {
        Rectangle()
            .fill(emptyGraphColor)
            .cornerRadius(2)
    }
    private var filledView: some View {
        Rectangle()
            .fill(filledGraphColor)
            .cornerRadius(2)
    }
    private var emptyRightView: some View {
        Rectangle()
            .fill(emptyGraphColor)
            .cornerRadius(2)
    }
    
    private func maskView(_ geometry: GeometryProxy) -> some View {
        let minHeight = 0
        let maxHeight = sortedPrices.lazy.map { $0.1 }.max() ?? 0
        let frame = geometry.frame(in: .global)
        let stepWidth: CGFloat = (frame.width) / CGFloat(sortedPrices.count)
        let stepHeight: CGFloat = (frame.height) / CGFloat(maxHeight - minHeight)
        
        return Path { path in
            var index: CGFloat = 0
            let x: CGFloat = 0
            let y: CGFloat = frame.height
            sortedPrices.forEach { _, value in
                let value: CGFloat = CGFloat(value) - CGFloat(minHeight)
                let subpath = Path { path in
                    path.move(to: CGPoint(x: x + 0.5 + index * stepWidth, y: y))
                    path.addLine(to: CGPoint(x: x + 0.5 + index * stepWidth, y: y - stepHeight * value))
                    path.addLine(to: CGPoint(x: x + (index + 1) * stepWidth, y: y - stepHeight * value))
                    path.addLine(to: CGPoint(x: x + (index + 1) * stepWidth, y: y))
                }
                path.addPath(subpath)
                index += 1
            }
        }
    }
}
