//
//  VPScrubber.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 04.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit

class VPScrubber: UISlider {
    
    var hitTestSlop = UIEdgeInsets.zero
    
    private let trackHeight: CGFloat = 5
    private let thumbSize: CGFloat = 9
    private let trackImage = UIImage(bundleImageNamed: "ScrubberTrack")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 2.5, bottom: 0, right: 2.5))
    
    private lazy var bufferTrackView = UIImageView(image: trackImage)
    let bufferTrackLayoutGuide = UILayoutGuide()
    private var bufferTrackWidthConstraint: NSLayoutConstraint!
    
    var bufferValue: Float = 0 {
        didSet {
            bufferTrackWidthConstraint.isActive = false
            bufferTrackWidthConstraint = bufferTrackView.widthAnchor.constraint(equalTo: bufferTrackLayoutGuide.widthAnchor, multiplier: CGFloat(bufferValue))
            bufferTrackWidthConstraint.isActive = true
        }
    }

    init() {
        super.init(frame: .zero)
        
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        hitTestSlop = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
        
        setThumbImage(UIImage(bundleImageNamed: "ScrubberThumb"), for: .normal)
        setThumbImage(UIImage(), for: .disabled)
        
        setMinimumTrackImage(trackImage, for: .normal)
        setMaximumTrackImage(trackImage, for: .normal)
        
        isContinuous = true
        
        minimumTrackTintColor = UIColor(hex: 0x7d7d7d)
        maximumTrackTintColor = UIColor(white: 1, alpha: 0.08)
        
        // bufferTrackView
        bufferTrackView.tintColor = UIColor(white: 1, alpha: 0.1)
        bufferTrackView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(bufferTrackView, at: 0)
        
        addLayoutGuide(bufferTrackLayoutGuide)
        
        bufferTrackLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -2).isActive = true
        bufferTrackLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 2).isActive = true
        bufferTrackLayoutGuide.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        bufferTrackWidthConstraint = bufferTrackView.widthAnchor.constraint(equalTo: bufferTrackLayoutGuide.widthAnchor, multiplier: 0)
        bufferTrackWidthConstraint.isActive = true
        bufferTrackView.heightAnchor.constraint(equalToConstant: trackHeight).isActive = true
        bufferTrackView.leadingAnchor.constraint(equalTo: bufferTrackLayoutGuide.leadingAnchor).isActive = true
        bufferTrackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isEnabled: Bool {
        didSet {
            if !isEnabled {
                value = 0
                bufferValue = 0
            }
            bufferTrackView.isHidden = !isEnabled
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if hitTestSlop == .zero {
            return super.point(inside: point, with: event)
        } else {
            return bounds.inset(by: hitTestSlop).contains(point)
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: 0)
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: -trackHeight / 2, width: bounds.width, height: trackHeight)
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let centerX = CGFloat(Float(bounds.width - thumbSize) * (value - minimumValue) / (maximumValue - minimumValue))
        
        return CGRect(x: centerX, y: -thumbSize / 2, width: thumbSize, height: thumbSize)
    }
    
}
