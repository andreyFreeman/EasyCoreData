//
//  UIView_animations.swift
//  pvm
//
//  Created by iFreeman on 11/01/15.
//  Copyright (c) 2015 lobo. All rights reserved.
//

import UIKit

extension CATransition {
	convenience init(fadeDuration:NSTimeInterval) {
		self.init()
		duration = fadeDuration
		timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		type = kCATransitionFade
	}
}

extension UIView {
	func runFade (duration: NSTimeInterval = 0.2) {
		layer.addAnimation(CATransition(fadeDuration: duration), forKey: nil)
	}
	func runShakeAnimation(duration: NSTimeInterval) {
		runShakeAnimation(duration, repeatCount: 2, xCenterOffset: 6.0)
	}
	func runShakeAnimation(duration: NSTimeInterval, repeatCount: Float, xCenterOffset: CGFloat) {
		let animation = CABasicAnimation(keyPath: "position")
		animation.duration = duration
		animation.repeatCount = repeatCount
		animation.autoreverses = true
		animation.fromValue = NSValue(CGPoint: CGPointMake(center.x - xCenterOffset, center.y))
		animation.toValue = NSValue(CGPoint: CGPointMake(center.x + xCenterOffset, center.y))
		layer.addAnimation(animation, forKey: "shake")
	}
	func startFadeInFadeOutAnimation(duration: NSTimeInterval = 0.75, repeatCount: Float = Float.infinity, fromValue: Float = 1, toValue: Float = 0, autoreverses: Bool = true) {
		let animation = CABasicAnimation(keyPath: "opacity")
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
		animation.fromValue = NSNumber(float: fromValue)
		animation.toValue = NSNumber(float: toValue)
		animation.duration = duration
		animation.autoreverses = autoreverses
		animation.repeatCount = repeatCount
		layer.addAnimation(animation, forKey:"fadeInOut")
	}
}
