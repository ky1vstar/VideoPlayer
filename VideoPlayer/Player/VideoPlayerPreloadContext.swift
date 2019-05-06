//
//  VideoPlayerPreloadContext.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 06.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import AVKit

open class VideoPlayerPreloadContext {
    
    private let identifier = UUID()
    private(set) var asset: AVAsset?
    private var didFinish = false
    open private(set) var isFailed = false
    
    internal var completionHandler: (() -> ())? {
        didSet {
            if didFinish {
                completionHandler?()
            }
        }
    }
    
    public init(url: URL) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let asset = AVURLAsset(url: url)
            
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                self.asset = asset
                self.loadValues(for: asset)
            }
        }
    }
    
    public init(asset: AVAsset) {
        self.asset = asset
        
        loadValues(for: asset)
    }
    
    private func loadValues(for asset: AVAsset) {
        asset.loadValuesAsynchronously(forKeys: ["playable", "duration", "tracks"]) { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                
                self.isFailed = !asset.isPlayable
                self.didFinish = true
                self.completionHandler?()
            }
        }
    }
    
    deinit {
        if !didFinish {
            asset?.cancelLoading()
        }
    }
    
}

// MARK: - Equatable
extension VideoPlayerPreloadContext: Equatable {
    
    public static func == (lhs: VideoPlayerPreloadContext, rhs: VideoPlayerPreloadContext) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
}
