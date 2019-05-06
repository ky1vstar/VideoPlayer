//
//  VPButton.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 04.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit

class VPButton: UIButton {
    
    var hitTestSlop = UIEdgeInsets.zero
    var hidesWhenDisabled = false {
        didSet {
            if hidesWhenDisabled && !isEnabled {
                isHidden = true
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        adjustsImageWhenHighlighted = false
        tintColor = UIColor(white: 1, alpha: 0.75)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isEnabled: Bool {
        didSet {
            if hidesWhenDisabled && !isEnabled {
                isHidden = true
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.75, y: 0.75) : .identity
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: super.intrinsicContentSize.width, height: 47)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if hitTestSlop == .zero {
            return super.point(inside: point, with: event)
        } else {
            return bounds.inset(by: hitTestSlop).contains(point)
        }
    }

}
