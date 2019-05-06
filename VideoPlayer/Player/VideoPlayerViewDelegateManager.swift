//
//  VideoPlayerViewDelegateManager.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 06.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import Foundation

class VideoPlayerViewDelegateManager: VideoPlayerViewDelegate {
    
    let delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    func kek() {
        print()
    }
    
    func enumerateDelegates(_ block: (VideoPlayerViewDelegate) -> ()) {
        let enumerator = delegates.objectEnumerator()
        
        while let delegate = enumerator.nextObject() as? VideoPlayerViewDelegate {
            block(delegate)
        }
    }
    
    func videoPlayerViewDidChangePlayer(_ videoPlayerView: VideoPlayerView) {
        enumerateDelegates {
            $0.videoPlayerViewDidChangePlayer?(videoPlayerView)
        }
    }
    
    func videoPlayerViewDidChangeReadinessForDisplay(_ videoPlayerView: VideoPlayerView) {
        enumerateDelegates {
            $0.videoPlayerViewDidChangeReadinessForDisplay?(videoPlayerView)
        }
    }
    
    func videoPlayerViewIsReadyToPlay(_ videoPlayerView: VideoPlayerView) {
        enumerateDelegates {
            $0.videoPlayerViewIsReadyToPlay?(videoPlayerView)
        }
    }
    
    func videoPlayerView(_ videoPlayerView: VideoPlayerView, didChangeStateFrom initialState: VideoPlayerView.State, to finalState: VideoPlayerView.State) {
        enumerateDelegates {
            $0.videoPlayerView?(videoPlayerView, didChangeStateFrom: initialState, to: finalState)
        }
    }
    
    func videoPlayerViewCurrentTimeDidChange(_ videoPlayerView: VideoPlayerView) {
        enumerateDelegates {
            $0.videoPlayerViewCurrentTimeDidChange?(videoPlayerView)
        }
    }
    
    func videoPlayerViewBufferSizeDidChange(_ videoPlayerView: VideoPlayerView) {
        enumerateDelegates {
            $0.videoPlayerViewBufferSizeDidChange?(videoPlayerView)
        }
    }
    
}
