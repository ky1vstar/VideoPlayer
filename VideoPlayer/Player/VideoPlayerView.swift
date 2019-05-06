//
//  VideoPlayerView.swift
//  Player_iOS
//
//  Created by KY1VSTAR on 02.03.2019.
//  Copyright © 2019 Patrick Piemonte. All rights reserved.
//

import UIKit
import AVFoundation

open class VideoPlayerView: UIView {
    
    @objc(VideoPlayerViewState)
    public enum State: Int {
        case idle
        case initializing
        case loading
        case playing
        case paused
        case finished
        case failed
    }
    
    // MARK: - Public properties
    override open class var layerClass: AnyClass {
        get {
            return AVPlayerLayer.self
        }
    }
    
    open var asset: AVAsset? {
        return preloadContext?.asset
    }
    
    open private(set) var videoOutput: AVPlayerItemVideoOutput?
    
    open private(set) var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
            
            delegateManager.videoPlayerViewDidChangePlayer(self)
        }
    }
    
    open private(set) var state = State.idle {
        didSet {
            if oldValue != state {
                delegateManager.videoPlayerView(self, didChangeStateFrom: oldValue, to: state)
            }
        }
    }
    
    open var shouldAutorepeat = false
    
    open var isReadyToPlay: Bool {
        return playerItem?.status == .readyToPlay
    }
    
    open var isReadyForDisplay: Bool {
        return playerLayer.isReadyForDisplay
    }
    
    open var isLive: Bool {
        return isReadyToPlay && (playerItem?.duration.isIndefinite ?? false)
    }
    
    open private(set) var shouldBePlaying = false
    
    open var isPlaying: Bool {
        if let player = player {
            return player.rate > 0 && player.error == nil
        } else {
            return false
        }
    }
    
    open var isMuted = false {
        didSet {
            player?.isMuted = isMuted
        }
    }
    
    // Maximum duration of playback.
    open var duration: TimeInterval? {
        get {
            let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function, d, "\n") } }
            
            guard let duration = playerItem?.asset.duration, !duration.isIndefinite else { return nil }
            
            return duration.seconds
        }
    }
    
    // Time interval of live video which can be caught up
    open var seekableDuration: TimeInterval? {
        return definiteSeekableTimeRange?.duration.seconds
    }
    
    open var shouldBeSeekable: Bool {
        if isLive, (seekableDuration ?? 0) < 30 {
            return false
        }
        return true
    }
    
    open var definiteCurrentTime: CMTime? {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        if let time = playerItem?.currentTime(), !time.isIndefinite {
            return time
        }
        return nil
    }
    
    open var displayableDefiniteCurrentTime: CMTime? {
        return currentSeekTime?.time ?? definiteCurrentTime
    }
    
    // Media playback's current time.
    open var currentTimeInterval: TimeInterval {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        if let playerItem = playerItem {
            return playerItem.currentTime().seconds
        } else {
            return 0
        }
    }
    
    open var displayableCurrentTimeInterval: TimeInterval {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        return displayableDefiniteCurrentTime?.seconds ?? 0
    }
    
    open var definiteSeekableTimeRange: CMTimeRange? {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        guard let seekableRange = playerItem?.seekableTimeRanges.last?.timeRangeValue, !seekableRange.isIndefinite else { return nil }
        
        return seekableRange
    }
    
    open var playedProgress: Double? {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        guard let seekableRange = definiteSeekableTimeRange else {
                return nil
        }
        
        let start = seekableRange.start.seconds
        let duration = seekableRange.duration.seconds
        
        return max(min((displayableCurrentTimeInterval - start) / duration, 1), 0)
    }
    
    open var bufferProgress: Double? {
        let t = Date(); defer { let d = -t.timeIntervalSinceNow; if d > 0.001 { print("[[]] for", #function,  d, "\n") } }
        
        guard let seekableRange = definiteSeekableTimeRange,
            let loadedRange = playerItem?.loadedTimeRanges.first?.timeRangeValue,
            !loadedRange.isIndefinite else {
                return nil
        }
        
        let start = seekableRange.start.seconds
        let duration = seekableRange.duration.seconds
        let bufferSize = loadedRange.end.seconds

        return max(min((bufferSize - start) / duration, 1), 0)
    }

    open override var contentMode: UIView.ContentMode {
        get {
            return super.contentMode
        }
        set {
            var finalValue = newValue
            let gravity: AVLayerVideoGravity
            
            switch newValue {
            case .scaleToFill:
                gravity = .resize
            case .scaleAspectFill:
                gravity = .resizeAspectFill
            default:
                finalValue = .scaleAspectFit
                gravity = .resizeAspect
            }
            
            super.contentMode = finalValue
            playerLayer.videoGravity = gravity
        }
    }
    
    // MARK: - Private properties
    private let queue = DispatchQueue(label: "VideoPlayerView.queue")
    private let delegateManager = VideoPlayerViewDelegateManager()
    
    private var currentSeekTime: SeekTime? {
        didSet {
            delegateManager.videoPlayerViewCurrentTimeDidChange(self)
        }
    }
    private var queuedSeekTime: SeekTime?
    
    private var setupURL: URL?
    private var preloadContext: VideoPlayerPreloadContext?
    private var playerItem: AVPlayerItem?
    
    private var playerLayerObservers = [NSKeyValueObservation]()
    private var playerItemObservers = [NSKeyValueObservation]()
    private var playerObservers = [NSKeyValueObservation]()
    private var playerTimeObserver: Any?
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    // MARK: - Constructors
    public convenience init(url: URL) {
        self.init(asset: AVURLAsset(url: url))
    }
    
    public init(asset: AVAsset? = nil) {
        super.init(frame: .zero)
        
        addPlayerLayerObservers(playerLayer)
        
        addApplicationObservers()
        
        if let asset = asset {
            setup(with: asset)
        }
        
        defer {
            contentMode = .scaleAspectFit
        }
    }
    
    public init(preloadContext: VideoPlayerPreloadContext) {
        super.init(frame: .zero)
        
        addPlayerLayerObservers(playerLayer)
        
        addApplicationObservers()
        
        setup(with: preloadContext)
        
        defer {
            contentMode = .scaleAspectFit
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addPlayerLayerObservers(playerLayer)
        
        addApplicationObservers()
        
        defer {
            (contentMode = contentMode)
        }
    }
    
    deinit {
        if let player = player {
            removePlayerObservers(player)
            player.pause()
        }
    }
    
}

// MARK: - Public methods
extension VideoPlayerView {
    
    open func setup(with url: URL) {
        setupWithPreloadContext(VideoPlayerPreloadContext(url: url), url: url)
    }
    
    open func setup(with asset: AVAsset) {
        setupWithPreloadContext(VideoPlayerPreloadContext(asset: asset), url: (asset as? AVURLAsset)?.url)
    }
    
    open func setup(with preloadContext: VideoPlayerPreloadContext) {
        setupWithPreloadContext(preloadContext, url: nil)
    }
    
    open func addDelegate(_ delegate: VideoPlayerViewDelegate) {
        delegateManager.delegates.add(delegate)
    }
    
    open func removeDelegate(_ delegate: VideoPlayerViewDelegate) {
        delegateManager.delegates.remove(delegate)
    }
    
    open func play() {
        shouldBePlaying = true
        player?.play()
    }
    
    open func pause() {
        shouldBePlaying = false
        player?.pause()
    }
    
    open func stop() {
        setupWithPreloadContext(nil, url: nil)
    }
    
    open func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, immediately: Bool = false, completionHandler: ((Bool) -> ())? = nil) {
        let time = normalizedTime(for: time)
        
        let seekTime = SeekTime(time: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
        var shouldSeek = false
        
        queuedSeekTime?.completion(false)
        
        if immediately {
            shouldSeek = true
            queuedSeekTime = nil
        } else if currentSeekTime != nil {
            queuedSeekTime = seekTime
        } else {
            shouldSeek = true
        }
        
        currentSeekTime = seekTime
        
        guard shouldSeek, let playerItem = playerItem else { return }
        
        playerItem.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) { [weak self] finished in
            guard let `self` = self else { return }
            
            seekTime.completion(finished)
            
            if seekTime == self.currentSeekTime {
                self.currentSeekTime = nil
                self.queuedSeekTime = nil
            } else if let queuedSeekTime = self.queuedSeekTime {
                self.queuedSeekTime = nil
                
                self.seek(to: queuedSeekTime.time, toleranceBefore: queuedSeekTime.toleranceBefore, toleranceAfter: queuedSeekTime.toleranceAfter, immediately: true, completionHandler: queuedSeekTime.completionHandler)
            }
        }
    }
    
    // FIXME
    open func seek(to progress: Double) {
        guard let playerItem = playerItem,
            let seekableRange = playerItem.seekableTimeRanges.last?.timeRangeValue,
            !seekableRange.duration.isIndefinite else {
                return
        }
        
        
        var duration = seekableRange.duration
        duration.value = Int64(Double(duration.value) * progress)
        
        playerItem.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    open func skipBack(for timeInterval: TimeInterval) {
        skip(for: -timeInterval)
    }
    
    open func skipAhead(for timeInterval: TimeInterval) {
        skip(for: timeInterval)
    }
    
}

// MARK: - Private methods
extension VideoPlayerView {
    
    private func normalizedTime(for time: CMTime) -> CMTime {
        guard let seekableRange = definiteSeekableTimeRange else { return time }
        
        return min(max(time, seekableRange.start), seekableRange.end)
    }
    
    private func skip(for timeInterval: TimeInterval) {
        guard let time = currentSeekTime?.time ?? playerItem?.currentTime(), !time.isIndefinite else { return }
        
        let halfASecond = CMTime(value: 1, timescale: 2)
        let desiredTime = time + CMTime(seconds: timeInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        seek(to: desiredTime, toleranceBefore: halfASecond, toleranceAfter: halfASecond)
    }
    
    func setupWithPreloadContext(_ preloadContext: VideoPlayerPreloadContext?, url: URL?) {
        let time = Date(); defer { print("setupWithPreloadContext", -time.timeIntervalSinceNow) }
        
        self.preloadContext = preloadContext
        setupURL = url
        currentSeekTime = nil
        queuedSeekTime = nil
        
        if let previousPlayerItem = playerItem {
            removePlayerItemObservers(previousPlayerItem)
            playerItem = nil
            
            videoOutput = nil
            
            if let player = player {
                removePlayerObservers(player)
                player.pause()
                
                self.player = nil
            }
        }
        
        guard let preloadContext = preloadContext else {
            state = .idle
            return
        }
        
        state = .initializing
        
        preloadContext.completionHandler = { [weak self, weak preloadContext] in
            guard let `self` = self, let preloadContext = preloadContext else {
                return
            }
            
            self.prepareToPlayPreloadContext(preloadContext)
        }
    }
    
    private func prepareToPlayPreloadContext(_ preloadContext: VideoPlayerPreloadContext) {
//        let time = Date(); defer { print("prepareToPlayAsset1", -time.timeIntervalSinceNow) }
        
        guard preloadContext == self.preloadContext, let asset = preloadContext.asset else { return }
        
        if !asset.isPlayable {
            state = .failed
            return
        }
        
        queue.async {
            let playerItem = AVPlayerItem(asset: asset)
            
            let playerItemVideoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes:
                [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                 kCVPixelBufferCGImageCompatibilityKey as String: true])
            playerItem.add(playerItemVideoOutput)
            
            let player = AVPlayer(playerItem: playerItem)
            
            DispatchQueue.main.async {
                guard preloadContext == self.preloadContext else { return }
                
                self.playerItem = playerItem
                self.addPlayerItemObservers(playerItem)
                
                if let seekTime = self.currentSeekTime {
                    self.seek(to: seekTime.time, toleranceBefore: seekTime.toleranceBefore, toleranceAfter: seekTime.toleranceAfter, immediately: true, completionHandler: seekTime.completionHandler)
                }
                
                self.videoOutput = playerItemVideoOutput
                
                player.isMuted = self.isMuted
                self.addPlayerObservers(player)
                
//                let time = Date(); defer { print("prepareToPlayAsset2", -time.timeIntervalSinceNow) }
                self.player = player
            }
        }
    }
    
    // MARK: PlayerLayer observers
    private func addPlayerLayerObservers(_ playerLayer: AVPlayerLayer) {
        playerLayerObservers.append(playerLayer.observe(\.isReadyForDisplay, options: [.old, .new], changeHandler: { [weak self] playerLayer, change in
            guard let `self` = self else { return }
            
            self.delegateManager.videoPlayerViewDidChangeReadinessForDisplay(self)
        }))
    }
    
    // MARK: PlayerItem observers
    private func addPlayerItemObservers(_ playerItem: AVPlayerItem) {
//        let time = Date(); defer { print("addPlayerItemObservers", -time.timeIntervalSinceNow) }
        
        playerItemObservers.append(playerItem.observe(\.status, options: [.old, .new], changeHandler: { [weak self] playerItem, change in
            guard let `self` = self else { return }
            
            switch playerItem.status {
            case .readyToPlay:
                self.delegateManager.videoPlayerViewIsReadyToPlay(self)
                
                if self.state != .playing, self.state != .loading, self.shouldBePlaying {
                    self.play()
                }
                
            case .failed:
                self.state = .failed
                print("Error: \(String(describing: self.player?.currentItem?.error?.localizedDescription)), error: \(String(describing: self.player?.currentItem?.error))")
                print()
                
            default:
                break
            }
        }))
        
        playerItemObservers.append(playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.old, .new], changeHandler: { [weak self] playerItem, change in
            guard let `self` = self else { return }
            
            let isPlaybackLikelyToKeepUp = playerItem.isPlaybackLikelyToKeepUp
            
            if isPlaybackLikelyToKeepUp && self.state == .playing {
                return
            }
            
            if isPlaybackLikelyToKeepUp && !self.shouldBePlaying {
                self.state = .paused
                return
            }
            
            self.state = .loading
            
            if self.shouldBePlaying && isPlaybackLikelyToKeepUp {
                self.play()
            }
        }))
        
        playerItemObservers.append(playerItem.observe(\.isPlaybackBufferEmpty, options: [.old, .new], changeHandler: { [weak self] playerItem, change in
            guard let `self` = self, self.shouldBePlaying, playerItem.isPlaybackBufferEmpty else { return }
            
            self.state = .loading
        }))
        
        playerItemObservers.append(playerItem.observe(\.loadedTimeRanges, options: [.old, .new], changeHandler: { [weak self] playerItem, change in
            guard let `self` = self else { return }
            
            self.delegateManager.videoPlayerViewBufferSizeDidChange(self)
        }))
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemPlaybackStalled), name: .AVPlayerItemPlaybackStalled, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemFailedToPlayToEndTime), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemNewErrorLogEntry), name: .AVPlayerItemNewErrorLogEntry, object: playerItem)
    }
    
    private func removePlayerItemObservers(_ playerItem: AVPlayerItem) {
        playerItemObservers = []
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemPlaybackStalled, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewErrorLogEntry, object: playerItem)
    }
    
    // MARK: Player observers
    private func addPlayerObservers(_ player: AVPlayer) {
//        let time = Date(); defer { print("addPlayerObservers", -time.timeIntervalSinceNow) }
        
        playerObservers.append(player.observe(\.rate, options: [.old, .new], changeHandler: { [weak self] player, change in
            guard let `self` = self else { return }
            
            // FIXME
            if player.rate == 0 {
                if self.state == .playing && self.state != .finished {
                    self.state = .paused
                }
            } else {
                self.state = .playing
            }
        }))
        
        playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 4), queue: .main) { [weak self] time in
            guard time.seconds >= 0, let `self` = self, self.isReadyToPlay else { return }
            
            self.delegateManager.videoPlayerViewCurrentTimeDidChange(self)
        }
    }
    
    private func removePlayerObservers(_ player: AVPlayer) {
        playerObservers = []
        
        if let playerTimeObserver = playerTimeObserver {
            player.removeTimeObserver(playerTimeObserver)
            self.playerTimeObserver = nil
        }
    }
    
    // MARK: Application observers
    func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
}

// MARK: - Notifications
extension VideoPlayerView {
    
    @objc private func playerItemDidPlayToEndTime() {
        state = .finished
        
        if shouldAutorepeat {
            seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero, immediately: true, completionHandler: nil)
            play()
        } else {
            pause()
        }
    }
    
    @objc private func playerItemPlaybackStalled() {
        state = .loading
    }
    
    @objc private func playerItemFailedToPlayToEndTime() {
        print("")
//        fatalError()
    }
    
    @objc private func playerItemNewErrorLogEntry() {
//        fatalError()
    }
    
    @objc private func applicationDidBecomeActive() {
        if state == .paused && shouldBePlaying {
            play()
        }
    }
    
    @objc private func applicationWillResignActive() {
        if state == .playing {
            pause()
            shouldBePlaying = true
        }
    }
    
}
