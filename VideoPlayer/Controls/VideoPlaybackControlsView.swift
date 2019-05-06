//
//  VideoPlaybackControlsView.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 04.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit
import AVFoundation

open class VideoPlaybackControlsView: UIView {
    
    private enum Style {
        case none
        case expandedHorizontally
        case expandedVertically
    }
    
    @IBOutlet public var videoPlayerView: VideoPlayerView? {
        didSet {
            if let oldValue = oldValue {
                oldValue.removeDelegate(self)
            }
            
            if videoPlayerView != oldValue {
                videoPlayerView?.addDelegate(self)
            }
            
            updateControls()
            updateBuffer()
        }
    }
    
    public var automaticallyHandlesTraitCollection = true
    
    // MARK: - Private properties
    private var style = Style.none
    private let emptyTimeText = "−−:−−"

    private var previousScrubberValue: Float?
    private var isScrubbing = false
    private var shouldPlayAfterScrubbing = false
    
    private let errorView = UIImageView(image: UIImage(bundleImageNamed: "PlaybackFailed"))
    
    private let backgroundView = UIView()
    private let stackView = UIStackView()
    private let liveBroadcastLabel = UILabel()
    
    private let scrubber = VPScrubber()
    private let leftTimeLabel = VPLabel()
    private let rightTimeLabel = VPLabel()
    
    private let skipBack15SecondsButton = VPButton()
    private let skipBackSpacingView = VPSpacingView(width: 33)
    private let largePlayPauseButton = VPButton()
    private let largePlayPauseSpacingView = VPSpacingView(width: 33)
    private let skipAhead15SecondsButton = VPButton()
    private let skipAheadSpacingView = VPSpacingView(width: 25)
    
    // MARK: - Constructors
    public init() {
        super.init(frame: .zero)
        
        setup()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: .zero)
        
        setup()
    }

    public init(videoPlayerView: VideoPlayerView) {
        super.init(frame: .zero)
        
        setup()
        
        defer {
            self.videoPlayerView = videoPlayerView
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard automaticallyHandlesTraitCollection else { return }
        
        if traitCollection.horizontalSizeClass == .compact {
            setupExpandedVertically()
        } else {
            setupExpandedHorizontally()
        }
    }
    
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        return hitView == self ? nil : hitView
    }
    
}

// MARK: - Private methods
extension VideoPlaybackControlsView {
    
    private func setup() {
        // errorView
        errorView.contentMode = .center
        errorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(errorView)
        
        errorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        errorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        errorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        errorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // backgroundView
        backgroundView.backgroundColor = UIColor(hex: 0x242424)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 16
        addSubview(backgroundView)
        
        let leadingConstraint: NSLayoutConstraint, trailingConstraint: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            leadingConstraint = backgroundView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 6)
            trailingConstraint = backgroundView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -6)
            backgroundView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -6).isActive = true
        } else {
            leadingConstraint = backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6)
            trailingConstraint = backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6)
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
        }
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint])
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            leadingConstraint.priority = .defaultLow
            trailingConstraint.priority = .defaultLow
            
            let width = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 12
            backgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: width).isActive = true
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
        
        // stackView
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 7
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(stackView)
        
        stackView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: backgroundView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor).isActive = true
        
        // liveBroadcastLabel
        liveBroadcastLabel.font = .systemFont(ofSize: 13)
        liveBroadcastLabel.textColor = UIColor(white: 1, alpha: 0.55)
        liveBroadcastLabel.text = VPLocalizedString("liveBroadcast")
        liveBroadcastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // scrubber
        scrubber.addTarget(self, action: #selector(beginScrubbing), for: .touchDown)
        scrubber.addTarget(self, action: #selector(scrubberValueChanged), for: .valueChanged)
        scrubber.addTarget(self, action: #selector(endScrubbing), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        scrubber.translatesAutoresizingMaskIntoConstraints = false
        
        // leftTimeLabel
        leftTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // rightTimeLabel
        rightTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // skipBack15SecondsButton
        skipBack15SecondsButton.hitTestSlop = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
        skipBack15SecondsButton.translatesAutoresizingMaskIntoConstraints = false
        skipBack15SecondsButton.setImage(UIImage(bundleImageNamed: "SkipBack15Seconds"), for: .normal)
        skipBack15SecondsButton.addTarget(self, action: #selector(skipBack15SecondsButtonTapped), for: .touchUpInside)
        
        // largePlayPauseButton
        largePlayPauseButton.hitTestSlop = UIEdgeInsets(top: -16, left: -22, bottom: -16, right: -22)
        largePlayPauseButton.translatesAutoresizingMaskIntoConstraints = false
        largePlayPauseButton.setImage(UIImage(bundleImageNamed: "PlayLarge"), for: .normal)
        largePlayPauseButton.setImage(UIImage(bundleImageNamed: "PauseLarge"), for: .selected)
        largePlayPauseButton.setImage(UIImage(bundleImageNamed: "PauseLarge"), for: [.selected, .highlighted])
        largePlayPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        
        // skipAhead15SecondsButton
        skipAhead15SecondsButton.hitTestSlop = UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16)
        skipAhead15SecondsButton.translatesAutoresizingMaskIntoConstraints = false
        skipAhead15SecondsButton.setImage(UIImage(bundleImageNamed: "SkipAhead15Seconds"), for: .normal)
        skipAhead15SecondsButton.addTarget(self, action: #selector(skipAhead15SecondsButtonTapped), for: .touchUpInside)
        
        
        setupExpandedVertically()
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = (totalSeconds % 3600) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func updateControls() {
        var isSeekable = true
        var isSkipButtonsEnabled = true
        
        defer {
            scrubber.isHidden = !isSeekable
            leftTimeLabel.isHidden = !isSeekable
            rightTimeLabel.isHidden = !isSeekable
            liveBroadcastLabel.isHidden = isSeekable
            
            skipBack15SecondsButton.isHidden = !isSeekable
            skipBack15SecondsButton.isEnabled = isSkipButtonsEnabled
            skipAhead15SecondsButton.isHidden = !isSeekable
            skipAhead15SecondsButton.isEnabled = isSkipButtonsEnabled
            
            skipBackSpacingView.isHidden = !isSeekable
            skipAheadSpacingView.isHidden = !isSeekable
        }
        
        errorView.isHidden = self.videoPlayerView?.state != .failed
        
        switch self.videoPlayerView?.state ?? .idle {
        case .idle, .initializing, .failed:
            scrubber.isEnabled = false
            
            leftTimeLabel.text = emptyTimeText
            
            rightTimeLabel.text = emptyTimeText
            
            largePlayPauseButton.isSelected = false
            largePlayPauseButton.isEnabled = false
            
            isSkipButtonsEnabled = false
            
            if self.videoPlayerView?.state != .failed {
                leftTimeLabel.startAnimating()
            }

            return
            
        default:
            break
        }
        
        let videoPlayerView = self.videoPlayerView!
        let state = videoPlayerView.state
        let currentTimeInterval = videoPlayerView.displayableCurrentTimeInterval
        
        largePlayPauseButton.isEnabled = true
        
        if let duration = videoPlayerView.duration {
            leftTimeLabel.text = formattedTime(currentTimeInterval)
            rightTimeLabel.text = "−" + formattedTime(duration - currentTimeInterval)
        } else if let seekableLiveDuration = videoPlayerView.seekableDuration {
            leftTimeLabel.text = "−" + formattedTime(seekableLiveDuration)
            rightTimeLabel.text = VPLocalizedString("live")
        }
        
        if let playedProgress = videoPlayerView.playedProgress {
            if !isScrubbing {
                scrubber.value = Float(playedProgress)
            }
            scrubber.isEnabled = true
        }
        
        isSeekable = videoPlayerView.shouldBeSeekable
        
        if state == .loading {
            leftTimeLabel.startAnimating()
        }
        
        largePlayPauseButton.isSelected = videoPlayerView.shouldBePlaying || isScrubbing && shouldPlayAfterScrubbing
    }
    
    private func updateBuffer() {
        scrubber.bufferValue = Float(videoPlayerView?.bufferProgress ?? 0)
    }
    
}

// MARK: - Layout
extension VideoPlaybackControlsView {
    
    open func setupExpandedVertically() {
        if style == .expandedVertically {
            return
        }
        style = .expandedVertically
        
        for subview in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        
        backgroundView.addSubview(liveBroadcastLabel)
        backgroundView.addSubview(scrubber)
        backgroundView.addSubview(leftTimeLabel)
        backgroundView.addSubview(rightTimeLabel)
        backgroundView.addSubview(skipBack15SecondsButton)
        backgroundView.addSubview(largePlayPauseButton)
        backgroundView.addSubview(skipAhead15SecondsButton)
        
        // liveBroadcastLabel
        liveBroadcastLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 15).isActive = true
        liveBroadcastLabel.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        
        // scrubber
        scrubber.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 22.5).isActive = true
        scrubber.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 18).isActive = true
        scrubber.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -18).isActive = true
        
        // leftTimeLabel
        leftTimeLabel.textAlignment = .left
        leftTimeLabel.reservedText = ""
        
        leftTimeLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16).isActive = true
        leftTimeLabel.topAnchor.constraint(equalTo: scrubber.topAnchor, constant: 9).isActive = true
        
        // rightTimeLabel
        rightTimeLabel.textAlignment = .left
        rightTimeLabel.reservedText = ""
        
        rightTimeLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -16).isActive = true
        rightTimeLabel.topAnchor.constraint(equalTo: scrubber.topAnchor, constant: 9).isActive = true
        
        // buttons
        let buttonsLayoutGuide = UILayoutGuide()
        backgroundView.addLayoutGuide(buttonsLayoutGuide)
        
        buttonsLayoutGuide.topAnchor.constraint(equalTo: leftTimeLabel.bottomAnchor, constant: -2).isActive = true
        buttonsLayoutGuide.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -4).isActive = true
        buttonsLayoutGuide.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        
        // skipBack15SecondsButton
        skipBack15SecondsButton.leadingAnchor.constraint(equalTo: buttonsLayoutGuide.leadingAnchor).isActive = true
        skipBack15SecondsButton.topAnchor.constraint(equalTo: buttonsLayoutGuide.topAnchor).isActive = true
        skipBack15SecondsButton.bottomAnchor.constraint(equalTo: buttonsLayoutGuide.bottomAnchor).isActive = true
        
        // largePlayPauseButton
        largePlayPauseButton.leadingAnchor.constraint(equalTo: skipBack15SecondsButton.trailingAnchor, constant: 32).isActive = true
        largePlayPauseButton.topAnchor.constraint(equalTo: buttonsLayoutGuide.topAnchor).isActive = true
        largePlayPauseButton.bottomAnchor.constraint(equalTo: buttonsLayoutGuide.bottomAnchor).isActive = true
        
        // skipAhead15SecondsButton
        skipAhead15SecondsButton.leadingAnchor.constraint(equalTo: largePlayPauseButton.trailingAnchor, constant: 32).isActive = true
        skipAhead15SecondsButton.trailingAnchor.constraint(equalTo: buttonsLayoutGuide.trailingAnchor).isActive = true
        skipAhead15SecondsButton.topAnchor.constraint(equalTo: buttonsLayoutGuide.topAnchor).isActive = true
        skipAhead15SecondsButton.bottomAnchor.constraint(equalTo: buttonsLayoutGuide.bottomAnchor).isActive = true
    }
    
    open func setupExpandedHorizontally() {
        if style == .expandedHorizontally {
            return
        }
        style = .expandedHorizontally
        
        for subview in backgroundView.subviews {
            if subview != stackView {
                subview.removeFromSuperview()
            }
        }
        
        stackView.addArrangedSubview(skipBack15SecondsButton)
        stackView.addArrangedSubview(skipBackSpacingView)
        stackView.addArrangedSubview(largePlayPauseButton)
        stackView.addArrangedSubview(largePlayPauseSpacingView)
        stackView.addArrangedSubview(skipAhead15SecondsButton)
        stackView.addArrangedSubview(skipAheadSpacingView)
        stackView.addArrangedSubview(leftTimeLabel)
        stackView.addArrangedSubview(scrubber)
        stackView.addArrangedSubview(rightTimeLabel)
        stackView.addArrangedSubview(liveBroadcastLabel)
        
        leftTimeLabel.textAlignment = .right
        leftTimeLabel.reservedText = emptyTimeText
    }
    
}

// MARK: - Action handlers
extension VideoPlaybackControlsView {
    
    @objc private func skipBack15SecondsButtonTapped() {
        videoPlayerView?.skipBack(for: 15)
    }
    
    @objc private func playPauseButtonTapped() {
        if largePlayPauseButton.isSelected {
            videoPlayerView?.pause()
        } else {
            videoPlayerView?.play()
        }
        
        largePlayPauseButton.isSelected = videoPlayerView?.shouldBePlaying ?? false
    }
    
    @objc private func skipAhead15SecondsButtonTapped() {
        videoPlayerView?.skipAhead(for: 15)
    }
    
    @objc private func beginScrubbing() {
        previousScrubberValue = scrubber.value
        isScrubbing = true
        shouldPlayAfterScrubbing = videoPlayerView?.shouldBePlaying ?? false
        
        videoPlayerView?.pause()
    }
    
    @objc private func scrubberValueChanged() {
        defer {
            previousScrubberValue = scrubber.value
        }
        
        guard let previousScrubberValue = previousScrubberValue,
            let videoPlayerView = videoPlayerView,
            let seekableRange = videoPlayerView.definiteSeekableTimeRange else {
                return
        }
        
        let duration = seekableRange.duration.seconds
        let timeDifference = max(min(abs(Double(scrubber.value - previousScrubberValue)) * duration, 15), 0)
        let tolerance = CMTime(seconds: timeDifference, preferredTimescale: 5000)

        let desiredTime = seekableRange.start + CMTime(seconds: Double(scrubber.value) * duration, preferredTimescale: 5000)
        
        if scrubber.value - previousScrubberValue > 0 {
            videoPlayerView.seek(to: desiredTime, toleranceBefore: tolerance, toleranceAfter: .zero, immediately: false, completionHandler: nil)
        } else {
            videoPlayerView.seek(to: desiredTime, toleranceBefore: .zero, toleranceAfter: tolerance, immediately: false, completionHandler: nil)
        }
    }
    
    @objc private func endScrubbing() {
        isScrubbing = false
        previousScrubberValue = nil
        
        if shouldPlayAfterScrubbing {
            videoPlayerView?.play()
        }
    }
    
}

// MARK: - VideoPlayerViewDelegate
extension VideoPlaybackControlsView: VideoPlayerViewDelegate {
    
    public func videoPlayerView(_ videoPlayerView: VideoPlayerView, didChangeStateFrom initialState: VideoPlayerView.State, to finalState: VideoPlayerView.State) {
        updateControls()
    }

    public func videoPlayerViewCurrentTimeDidChange(_ videoPlayerView: VideoPlayerView) {
        updateControls()
    }

    public func videoPlayerViewBufferSizeDidChange(_ videoPlayerView: VideoPlayerView) {
        updateBuffer()
    }
    
}
