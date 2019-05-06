//
//  UIImage+VideoPlayer.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 04.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit

func VPLocalizedString(_ key: String) -> String {
    return NSLocalizedString(key, tableName: "VideoPlayer", bundle: .videoPlayerBundle, comment: "")
}

extension Bundle {
    
    static let videoPlayerBundle = Bundle(for: VideoPlaybackControlsView.self)
    
}

extension UIImage {
    
    convenience init?(bundleImageNamed name: String) {
        self.init(named: name, in: .videoPlayerBundle, compatibleWith: nil)
    }
    
}

extension UIColor {
    
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let red = (hex >> 16) & 0xff
        let green = (hex >> 8) & 0xff
        let blue = hex & 0xff
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
    
}
