//
//  VPSpacingView.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 05.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit

class VPSpacingView: UIView {
    
    let width: CGFloat

    init(width: CGFloat) {
        self.width = width
        
        super.init(frame: .zero)
        
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: width, height: 0)
    }
    
}
