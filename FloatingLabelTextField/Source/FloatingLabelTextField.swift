//
//  FloatingLabelTextField.swift
//  FloatingLabelTextField
//
//  Created by Eric Baker on 8/Nov/2017.
//  Copyright © 2017 DuneParkSoftware, LLC. All rights reserved.
//

/*
 The MIT License (MIT)

 Copyright (c) 2015-2017 DuneParkSoftware, LLC

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import UIKit


/// A subclass of `UITextField` which provides the "floating label" pattern described at
/// http://dribbble.com/shots/1254439--GIF-Mobile-Form-Interaction?list=users
///
/// To use with Interface Builder:
///     - Drag a UITextField onto your view
///     - Set the text field's class to `FloatingLabelTextField`
@IBDesignable
open class FloatingLabelTextField: UITextField {

    fileprivate struct Defaults {
        static let useBottomLineBorderStyle = false
        static let bottomLineBorderColor: UIColor = .gray
        static let bottomLineBorderHeight: CGFloat = 1.0
        static let minimumBottomLineBorderHeight: CGFloat = 0.5
        static let bottomLineBorderTopMargin: CGFloat = 1.0
        static let floatingLabelBottomMargin: CGFloat = 2.0
        static let floatingLabelFontScale: CGFloat = 1.0
        static let floatingLabelFontScaleMinimumValue: CGFloat = 0.5
        static let floatingLabelInactiveColor: UIColor = .gray
        static let floatAnimationDuration = TimeInterval(0.3)
        static let colorChangeAnimationDuration = TimeInterval(0.2)
    }

    fileprivate weak var bottomLineBorderView: UIView?
    fileprivate weak var bottomLineBorderViewHeightConstraint: NSLayoutConstraint?
    fileprivate weak var bottomLineBorderViewTopConstraint: NSLayoutConstraint?
    fileprivate var originalBorderStyle: UITextBorderStyle? = nil
    fileprivate var originalPlaceholder: NSAttributedString? = nil
    fileprivate weak var floatingLabel: UILabel? = nil
    fileprivate weak var floatingLabelBaselineConstraint: NSLayoutConstraint? = nil

    /// Specifies whether the text field should use a single bottom line for its border.
    ///
    /// If this is `true`, the text field's `borderStyle` setting is ignored. Default is `false`.
    ///
    /// - seealso:
    /// `bottomLineBorderColor`, `bottomLineBorderHeight`
    @IBInspectable open dynamic var useBottomLineBorderStyle: Bool = Defaults.useBottomLineBorderStyle {
        didSet {
            if useBottomLineBorderStyle {
                // Force border style to be "none" so the bottom border line is visible.
                originalBorderStyle = borderStyle
                borderStyle = .none
            }
            else {
                // Restore the original border style if previously set.
                if let originalBorderStyle = originalBorderStyle {
                    DispatchQueue.main.async { [unowned self] in self.borderStyle = originalBorderStyle }
                }
            }

            updateBottomLineBorderView()
        }
    }

    /// Gets or sets the color of the bottom line border. Default color is gray.
    ///
    /// -seealso:
    /// `useBottomLineBorderStyle`, `bottomLineBorderHeight`
    @IBInspectable open dynamic var bottomLineBorderColor: UIColor = Defaults.bottomLineBorderColor {
        didSet {
            DispatchQueue.main.async { [unowned self] in self.bottomLineBorderView?.backgroundColor = self.bottomLineBorderColor }
        }
    }

    private var _bottomLineBorderHeight: CGFloat = Defaults.bottomLineBorderHeight {
        didSet {
            if let constraint = bottomLineBorderViewHeightConstraint {
                DispatchQueue.main.async { [unowned self, constraint] in constraint.constant = self._bottomLineBorderHeight }
            }
        }
    }

    /// Gets or sets the height of the bottom line border. Default is 1.0.
    ///
    /// -seealso:
    /// `useBottomLineBorderStyle`, `bottomLineBorderColor`
    @IBInspectable open dynamic var bottomLineBorderHeight: CGFloat {
        get {
            return _bottomLineBorderHeight
        }
        set {
            _bottomLineBorderHeight = max(newValue, Defaults.minimumBottomLineBorderHeight)
        }
    }

    /// Gets or sets the space between the top of the bottom border line, and the bottom of the text field.
    /// Default is 1.0
    @IBInspectable open dynamic var bottomLineBorderTopMargin: CGFloat = Defaults.bottomLineBorderTopMargin {
        didSet {
            if let constraint = bottomLineBorderViewTopConstraint {
                DispatchQueue.main.async { [unowned self, constraint] in constraint.constant = self.bottomLineBorderTopMargin }
            }
        }
    }

    private var _floatingLabelFont: UIFont? = nil

    /// Gets or sets the font to use for the floating label.
    ///
    /// If not set, the label will use the text field's font.
    ///
    /// -seealso:
    /// `floatingLabelFontScale`
    @objc open dynamic var floatingLabelFont: UIFont {
        get {
            let labelFont = _floatingLabelFont ?? font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
            return UIFont(descriptor: labelFont.fontDescriptor, size: labelFont.pointSize * floatingLabelFontScale)
        }
        set {
            _floatingLabelFont = newValue
        }
    }

    private var _floatingLabelFontScale: CGFloat = Defaults.floatingLabelFontScale

    /// Gets or sets the font size scale for the floating label. The scale is multiplied by the label's font point size.
    ///
    /// -seealso:
    /// `floatingLabelFont`
    @IBInspectable open dynamic var floatingLabelFontScale: CGFloat {
        get {
            return _floatingLabelFontScale
        }
        set {
            _floatingLabelFontScale = max(newValue, Defaults.floatingLabelFontScaleMinimumValue)
        }
    }

    private var _floatingLabelBottomMargin: CGFloat = Defaults.floatingLabelBottomMargin

    /// Gets or sets the vertical space between the bottom of the floating label and the top of the text field.
    /// Defaults to 2.0.
    @IBInspectable open dynamic var floatingLabelBottomMargin: CGFloat {
        get {
            return _floatingLabelBottomMargin
        }
        set {
            _floatingLabelBottomMargin = max(newValue, 0.0)
        }
    }

    private var _floatingLabelActiveColor: UIColor? = nil {
        didSet {
            if let label = floatingLabel {
                DispatchQueue.main.async { [unowned self, label] in label.textColor = self._floatingLabelActiveColor }
            }
        }
    }

    /// Gets or sets the floating label color while the text field is the first responder. By default, the text field's
    /// `tintColor` is used.
    ///
    /// -seealso:
    /// `floatingLabelInactiveColor`
    @IBInspectable open dynamic var floatingLabelActiveColor: UIColor {
        get {
            return _floatingLabelActiveColor ?? tintColor
        }
        set {
            _floatingLabelActiveColor = newValue
        }
    }

    /// Gets or sets the floating label color while the text field is not the first responder. By default, the color is
    /// gray. If `nil`, then the active color is used.
    ///
    /// -seealso:
    /// `floatingLabelActiveColor`
    @IBInspectable open dynamic var floatingLabelInactiveColor: UIColor? = Defaults.floatingLabelInactiveColor

    open override var borderStyle: UITextBorderStyle {
        get {
            return super.borderStyle
        }
        set {
            if originalBorderStyle == nil {
                originalBorderStyle = newValue
            }

            if useBottomLineBorderStyle {
                super.borderStyle = .none
            }
            else {
                super.borderStyle = newValue
            }
        }
    }

    open override var text: String? {
        get {
            return super.text
        }
        set {
            super.text = newValue

            if !isFirstResponder {
                updateFloatingLabelVisibility(animated: false)
            }
        }
    }

    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = ceil(max(size.height, font?.lineHeight ?? size.height))

        if useBottomLineBorderStyle {
            size.height += ceil(bottomLineBorderTopMargin + bottomLineBorderHeight)
        }

        return size
    }
}

// MARK:- Floating Label Support

extension FloatingLabelTextField {
    open override func becomeFirstResponder() -> Bool {
        let becameFirstResponder = super.becomeFirstResponder()
        if becameFirstResponder {
            DispatchQueue.main.async { [unowned self] in
                self.presentFloatingLabel()
            }
        }
        return becameFirstResponder
    }

    open override func resignFirstResponder() -> Bool {
        let resignedFirstResponder = super.resignFirstResponder()
        if resignedFirstResponder {
            DispatchQueue.main.async { [unowned self] in
                self.dismissFloatingLabel()
            }
        }
        return resignedFirstResponder
    }

    fileprivate func updateFloatingLabelVisibility(animated: Bool = true) {
        DispatchQueue.main.async { [unowned self] in
            if self.text != nil && !self.text!.isEmpty {
                self.presentFloatingLabel(animated: animated)
            }
            else {
                self.dismissFloatingLabel(animated: animated)
            }
        }
    }

    private func presentFloatingLabel(animated: Bool = true) {
        guard
            let placeholder = placeholder,
            !placeholder.isEmpty
            else {
                updateFloatingLabelTextColor()
                return
        }

        originalPlaceholder = attributedPlaceholder ?? NSAttributedString(string: placeholder)
        self.placeholder = nil

        let label = UILabel()
        label.text = placeholder
        label.font = floatingLabelFont
        label.sizeToFit()
        label.textColor = floatingLabelActiveColor
        label.alpha = 0.0
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        let baselineConstraint = label.firstBaselineAnchor.constraint(equalTo: firstBaselineAnchor)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            baselineConstraint
            ])

        let completeState = { [unowned self, label] in
            baselineConstraint.constant = -(self.bounds.size.height + self.floatingLabelBottomMargin)
            label.alpha = 1.0
        }

        if animated {
            layoutIfNeeded()
            UIView.animate(withDuration: Defaults.floatAnimationDuration) { _ in
                completeState()
                self.layoutIfNeeded()
            }
        }
        else {
            completeState()
        }

        floatingLabel = label
        floatingLabelBaselineConstraint = baselineConstraint
    }

    private func dismissFloatingLabel(animated: Bool = true) {
        guard
            text?.isEmpty ?? true,
            let placeholder = originalPlaceholder,
            let label = floatingLabel,
            let baselineConstraint = floatingLabelBaselineConstraint
            else {
                updateFloatingLabelTextColor()
                return
        }

        let completeState = { [unowned self, label] in
            self.attributedPlaceholder = placeholder
            self.originalPlaceholder = nil

            label.removeFromSuperview()
            self.floatingLabel = nil
            self.floatingLabelBaselineConstraint = nil
        }

        if animated {
            layoutIfNeeded()
            UIView.animate(withDuration: Defaults.floatAnimationDuration, animations: { [unowned self, label, baselineConstraint] in
                baselineConstraint.constant = 0.0
                label.alpha = 0.0
                self.layoutIfNeeded()
            }) { _ in
                completeState()
            }
        }
        else {
            completeState()
        }
    }

    private func updateFloatingLabelTextColor() {
        guard let label = floatingLabel else {
            return
        }

        let color: UIColor = isFirstResponder ? floatingLabelActiveColor : (floatingLabelInactiveColor ?? Defaults.floatingLabelInactiveColor)

        if isFirstResponder {
            UIView.transition(with: label, duration: Defaults.colorChangeAnimationDuration, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: { [unowned label, color] in
                label.textColor = color
            })
        }
        else {
            label.textColor = color
        }
    }
}

// MARK:- Bottom Line Border View

extension FloatingLabelTextField {
    fileprivate func updateBottomLineBorderView() {
        // If `useBottomLineBorderStyle` is enabled and the bottom line view is not present, then install it.
        if useBottomLineBorderStyle && bottomLineBorderView == nil {
            installBottomLineBorderView()
        }

        // If `useBottomLineBorderStyle` is disabled and the bottom line view is present, then remove it.
        if !useBottomLineBorderStyle && bottomLineBorderView != nil {
            removeBottomLineBorderView()
        }
    }

    fileprivate func installBottomLineBorderView() {
        let view = UIView()
        view.backgroundColor = bottomLineBorderColor
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: bottomLineBorderHeight)
        let topConstraint = view.topAnchor.constraint(equalTo: bottomAnchor, constant: bottomLineBorderTopMargin)
        NSLayoutConstraint.activate([
            view.leftAnchor.constraint(equalTo: leftAnchor),
            view.rightAnchor.constraint(equalTo: rightAnchor),
            topConstraint,
            heightConstraint
            ])

        bottomLineBorderView = view
        bottomLineBorderViewHeightConstraint = heightConstraint
        bottomLineBorderViewTopConstraint = topConstraint
    }
    
    fileprivate func removeBottomLineBorderView() {
        bottomLineBorderView?.removeFromSuperview()
        bottomLineBorderView = nil
        bottomLineBorderViewHeightConstraint = nil
        bottomLineBorderViewTopConstraint = nil
    }
}
