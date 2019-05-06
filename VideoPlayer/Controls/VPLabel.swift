//
//  VPLabel.swift
//  VideoPlayerDemo
//
//  Created by KY1VSTAR on 04.03.2019.
//  Copyright © 2019 KY1VSTAR. All rights reserved.
//

import UIKit

class VPLabel: UIView {
    
    private var activityIndicatorLeadingConstraint: NSLayoutConstraint!
    private var activityIndicatorTrailingConstraint: NSLayoutConstraint!

    private let reservedLabel = UILabel()
    private let mainLabel = UILabel()
    private let activityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.init(rawValue: 3)!)
    
    init() {
        super.init(frame: .zero)
        
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        
        // mainLabel
        mainLabel.font = font
        mainLabel.textColor = UIColor(white: 1, alpha: 0.55)
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainLabel)
        
        mainLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mainLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        mainLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mainLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // reservedLabel
        reservedLabel.isHidden = true
        reservedLabel.font = font
        reservedLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(reservedLabel)
        
        reservedLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        reservedLabel.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        reservedLabel.topAnchor.constraint(equalTo: topAnchor).isActive = true
        reservedLabel.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // activityIndicatorView
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.isHidden = true
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        
        activityIndicatorLeadingConstraint = activityIndicatorView.leadingAnchor.constraint(equalTo: leadingAnchor)
        activityIndicatorLeadingConstraint.isActive = true
        activityIndicatorTrailingConstraint = activityIndicatorView.trailingAnchor.constraint(equalTo: trailingAnchor)
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var text = "" {
        didSet {
            mainLabel.text = text
            mainLabel.isHidden = false
            
            if activityIndicatorView.isAnimating {
                activityIndicatorView.stopAnimating()
            }
        }
    }
    
    var reservedText = "" {
        didSet {
            reservedLabel.text = reservedText
        }
    }
    
    var textAlignment = NSTextAlignment.natural {
        didSet {
            mainLabel.textAlignment = textAlignment
            
            if textAlignment == .right {
                activityIndicatorLeadingConstraint.isActive = false
                activityIndicatorTrailingConstraint.isActive = true
            } else {
                activityIndicatorTrailingConstraint.isActive = false
                activityIndicatorLeadingConstraint.isActive = true
            }
        }
    }
    
    func startAnimating() {
        mainLabel.isHidden = true
        
        if !activityIndicatorView.isAnimating {
            activityIndicatorView.startAnimating()
        }
    }
    
}
