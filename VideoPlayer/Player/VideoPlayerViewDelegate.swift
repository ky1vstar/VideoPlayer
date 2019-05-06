//
//  VideoPlayerViewDelegate.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 06.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import Foundation

@objc public protocol VideoPlayerViewDelegate: class {
    
    @objc optional func videoPlayerViewDidChangePlayer(_ videoPlayerView: VideoPlayerView)
    
    @objc optional func videoPlayerViewDidChangeReadinessForDisplay(_ videoPlayerView: VideoPlayerView)
    
    @objc optional func videoPlayerViewIsReadyToPlay(_ videoPlayerView: VideoPlayerView)
    
    @objc optional func videoPlayerView(_ videoPlayerView: VideoPlayerView, didChangeStateFrom initialState: VideoPlayerView.State, to finalState: VideoPlayerView.State)
    
    @objc optional func videoPlayerViewCurrentTimeDidChange(_ videoPlayerView: VideoPlayerView)
    
    @objc optional func videoPlayerViewBufferSizeDidChange(_ videoPlayerView: VideoPlayerView)
    
}

//public extension VideoPlayerViewDelegate {
//    
//    func videoPlayerViewDidChangeReadinessForDisplay(_ videoPlayerView: VideoPlayerView) {}
//    
//    func videoPlayerViewIsReadyToPlay(_ videoPlayerView: VideoPlayerView) {}
//    
//    func videoPlayerView(_ videoPlayerView: VideoPlayerView, didChangeStateFrom initialState: VideoPlayerView.State, to finalState: VideoPlayerView.State) {}
//    
//    func videoPlayerViewCurrentTimeDidChange(_ videoPlayerView: VideoPlayerView) {}
//    
//    func videoPlayerViewBufferSizeDidChange(_ videoPlayerView: VideoPlayerView) {}
//    
//}
