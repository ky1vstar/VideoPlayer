//
//  SeekTime.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 07.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import AVFoundation

class SeekTime: NSObject {
    
    let time: CMTime
    let toleranceBefore: CMTime
    let toleranceAfter: CMTime
    let completionHandler: ((Bool) -> ())?
    
    var isCompleted = false
    
    init(time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: ((Bool) -> ())?) {
        self.time = time
        self.toleranceBefore = toleranceBefore
        self.toleranceAfter = toleranceAfter
        self.completionHandler = completionHandler
    }
    
    func completion(_ finished: Bool) {
        if isCompleted {
            return
        }
        isCompleted = true
        
        completionHandler?(finished)
    }
    
}
