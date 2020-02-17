//
//  ViewController.swift
//  PriceFilter
//
//  Created by Roman Kyrylenko on 12.02.2020.
//  Copyright © 2020 Roman Kyrylenko. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    @IBOutlet private var label: UILabel!
    @IBOutlet private var slider: Slider!
    
    @IBAction private func sliderValueChanged(_ slider: Slider) {
        label.text = "From \((slider.fromValue * 10).rounded() / 10) to \((slider.toValue * 10).rounded() / 10)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        slider.prices = [
            (0...1): 500, (1...2): 1000, (2...3): 1500, (3...4): 1700, (4...5): 1850, (5...6): 2300,
            (6...7): 2000, (7...8): 1725, (8...9): 1200, (9...10): 750, (10...11): 2000, (11...12): 1725, (12...13): 1200, (13...14): 750
        ]
        slider.fromValue = 3.5
        slider.toValue = 12.55
    }
}

public class Slider: UIControl {
    
    // MARK: - Public
    
    public var prices: [ClosedRange<Int>: Int] = [:] {
        didSet { sortPrices() }
    }
    public var fromValue: CGFloat = 0 {
        didSet { repositionThumbs() }
    }
    public var toValue: CGFloat = 0 {
        didSet { repositionThumbs() }
    }
    
    // MARK: - Appearance
    
    let thumbSide: CGFloat = 25
    let progressLineHeight: CGFloat = 3
    let emptyGraphColor = UIColor(red: 230 / 255, green: 231 / 255, blue: 232 / 255, alpha: 1)
    let filledGraphColor = UIColor(red: 255 / 255, green: 142 / 255, blue: 156 / 255, alpha: 1)
    let emptyLineColor = UIColor(red: 230 / 255, green: 231 / 255, blue: 232 / 255, alpha: 1)
    let filledLineColor = UIColor(red: 255 / 255, green: 64 / 255, blue: 105 / 255, alpha: 1)
    let thumbColor = UIColor.white
    let thumbShadowColor = UIColor(red: 12 / 255, green: 24 / 255, blue: 35 / 255, alpha: 0.35)
    
    // MARK: - Internals
    
    private var sortedPrices: [(ClosedRange<Int>, Int)] = [] {
        didSet {
            fulfilGraphLayer()
        }
    }
    
    private let leftThumb = UIView()
    private let rightThumb = UIView()
    
    private let emptyLeftLine = UIView()
    private let filledLine = UIView()
    private let emptyRightLine = UIView()
    
    private let emptyLeftView = UIView()
    private let filledView = UIView()
    private let emptyRightView = UIView()
    private let contentView = UIView()
    
    override public var frame: CGRect {
        didSet { adjustSubviews() }
    }
    
    override public var bounds: CGRect {
        didSet { adjustSubviews() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialise()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialise()
    }
}

extension Slider {
    
    private func initialise() {
        addSubview(contentView)
        for view in [filledView, emptyLeftView, emptyRightView] {
            contentView.addSubview(view)
        }
        for line in [emptyLeftLine, emptyRightLine, filledLine] {
            addSubview(line)
            line.layer.cornerRadius = 2
        }
        for thumb in [leftThumb, rightThumb] {
            addSubview(thumb)
            thumb.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(didMoveThumb(gestureRecognizer:))))
        }
        setupAppearance()
    }
    
    open func setupAppearance() {
        emptyLeftView.backgroundColor = emptyGraphColor
        emptyRightView.backgroundColor = emptyGraphColor
        filledView.backgroundColor = filledGraphColor
        emptyRightLine.backgroundColor = emptyLineColor
        emptyLeftLine.backgroundColor = emptyLineColor
        filledLine.backgroundColor = filledLineColor
        for thumb in [leftThumb, rightThumb] {
            thumb.backgroundColor = thumbColor
            thumb.layer.cornerRadius = thumbSide / 2
            thumb.layer.shadowColor = thumbShadowColor.cgColor
            thumb.layer.shadowOpacity = 1
            thumb.layer.shadowOffset = CGSize(width: 0, height: 1)
            thumb.layer.shadowRadius = 3
        }
    }
    
    // MARK: - Drawing
    
    @objc
    private func didMoveThumb(gestureRecognizer: UIPanGestureRecognizer) {
        guard let thumb = gestureRecognizer.view else {
            return
        }
        
        let movement = gestureRecognizer.translation(in: thumb.superview)
        thumb.center.x += movement.x
        restrictPosition(of: thumb)
        
        gestureRecognizer.setTranslation(.zero, in: thumb.superview)
        updateProgressLines()
        updateValues()
    }
    
    private func adjustSubviews() {
        contentView.frame = bounds
        filledView.frame = bounds
        if leftThumb.frame.size == .zero { // first time
            leftThumb.frame = CGRect(x: 0, y: bounds.height - thumbSide, width: thumbSide, height: thumbSide)
            rightThumb.frame = CGRect(x: bounds.width - thumbSide, y: bounds.height - thumbSide, width: thumbSide, height: thumbSide)
        } else {
            restrictPosition(of: leftThumb)
            restrictPosition(of: rightThumb)
        }
        updateProgressLines()
        fulfilGraphLayer()
    }
    
    private func updateProgressLines() {
        emptyLeftLine.frame = CGRect(
            x: 0,
            y: leftThumb.center.y - progressLineHeight / 2,
            width: leftThumb.center.x,
            height: progressLineHeight
        )
        filledLine.frame = CGRect(
            x: leftThumb.center.x,
            y: leftThumb.center.y - progressLineHeight / 2,
            width: rightThumb.center.x - leftThumb.center.x,
            height: progressLineHeight
        )
        emptyRightLine.frame = CGRect(
            x: rightThumb.center.x,
            y: leftThumb.center.y - progressLineHeight / 2,
            width: bounds.width - rightThumb.center.x,
            height: progressLineHeight
        )
        emptyLeftView.frame = CGRect(
            x: emptyLeftLine.frame.origin.x, y: 0, width: emptyLeftLine.frame.width, height: bounds.height
        )
        emptyRightView.frame = CGRect(
            x: emptyRightLine.frame.origin.x, y: 0, width: emptyRightLine.frame.width, height: bounds.height
        )
    }
    
    private func fulfilGraphLayer() {
        let maxHeight = prices.values.max() ?? 0
        let minHeight = 0
        let stepWidth: CGFloat = (bounds.width - thumbSide) / CGFloat(sortedPrices.count)
        let stepHeight: CGFloat = (bounds.height - thumbSide) / CGFloat(maxHeight - minHeight)
        let path = UIBezierPath()
        var index: CGFloat = 0
        let x: CGFloat = thumbSide / 2
        let y: CGFloat = filledLine.frame.minY
        sortedPrices.forEach { _, value in
            let subpath = UIBezierPath()
            let value: CGFloat = CGFloat(value) - CGFloat(minHeight)
            subpath.move(to: CGPoint(x: x + 0.5 + index * stepWidth, y: y))
            subpath.addLine(to: CGPoint(x: x + 0.5 + index * stepWidth, y: y - stepHeight * value))
            subpath.addLine(to: CGPoint(x: x + (index + 1) * stepWidth, y: y - stepHeight * value))
            subpath.addLine(to: CGPoint(x: x + (index + 1) * stepWidth, y: y))
            subpath.close()
            path.append(subpath)
            index += 1
        }
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        contentView.layer.mask = maskLayer
    }
    
    // MARK: - Supplementary
    
    private func restrictPosition(of thumb: UIView) {
        thumb.frame = CGRect(
            x: min(bounds.width - thumbSide, max(0, thumb.frame.origin.x)),
            y: bounds.height - thumbSide,
            width: thumbSide,
            height: thumbSide
        )

        let minSpacing: CGFloat = thumbSide / 3
        if thumb == leftThumb, leftThumb.frame.origin.x + thumbSide + minSpacing > rightThumb.frame.origin.x {
            leftThumb.frame.origin.x = rightThumb.frame.origin.x - thumbSide - minSpacing
        } else if thumb == rightThumb, rightThumb.frame.origin.x - minSpacing < leftThumb.frame.origin.x + thumbSide {
            rightThumb.frame.origin.x = leftThumb.frame.origin.x + thumbSide + minSpacing
        }
    }
    
    private func updateValues() {
        guard let lowerBound = sortedPrices.first?.0.lowerBound,
            let upperBound = sortedPrices.last?.0.upperBound else {
                return
        }
        
        let fromPercentage: CGFloat = (leftThumb.center.x - thumbSide / 2) / (bounds.width - thumbSide)
        let toPercentage: CGFloat = (rightThumb.center.x - thumbSide / 2) / (bounds.width - thumbSide)
        fromValue = fromPercentage * CGFloat(lowerBound + (upperBound - lowerBound))
        toValue = toPercentage * CGFloat(lowerBound + (upperBound - lowerBound))
        sendActions(for: .valueChanged)
    }
    
    private func repositionThumbs() {
        guard let lowerBound = sortedPrices.first?.0.lowerBound,
            let upperBound = sortedPrices.last?.0.upperBound else {
                return
        }
        
        let fromValue = min(self.fromValue, self.toValue)
        let toValue = max(self.fromValue, self.toValue)
        let fromPercentage: CGFloat = fromValue / CGFloat(upperBound - lowerBound)
        let toPercentage: CGFloat = toValue / CGFloat(upperBound - lowerBound)
        leftThumb.center.x = thumbSide / 2 + fromPercentage * (bounds.width - thumbSide)
        rightThumb.center.x = thumbSide / 2 + toPercentage * (bounds.width - thumbSide)
        updateProgressLines()
        sendActions(for: .valueChanged)
    }
    
    private func sortPrices() {
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
            self.sortedPrices = sortedPrices.sorted { lhs, rhs -> Bool in
                lhs.key.lowerBound < rhs.key.lowerBound
            }
        } else {
            self.sortedPrices = sortedPrices
        }
    }
}
