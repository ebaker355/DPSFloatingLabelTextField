//
//  FloatingLabelTextField.swift
//  DPSFloatingLabelTextField
//
//  Created by Eric Baker on 16/May/2015.
//  Copyright (c) 2015 DuneParkSoftware, LLC. All rights reserved.
//

// The MIT License (MIT)
//
// Copyright (c) 2015 ebaker355
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import UIKit

private let YES = true
private let NO = false

public class FloatingLabelTextField: UITextField {

    // Wait until the text field is drawn before we begin making visual changes.
    private var textFieldDidDrawRect: Bool = NO

    // The UILabel that acts as the floating label should be baseline-aligned
    // with the text field. It should be placed in its visible position in IB.
    @IBOutlet internal(set) weak var floatingLabel: UILabel?

    // Connect this to the label <--> text field baseline constraint.
    // This constraint's constant is set to 0, causing the label to hide; it
    // is set to whatever its value is in IB, causing the label to appear.
    @IBOutlet internal(set) weak var baselineConstraint: NSLayoutConstraint?

    // Override the IB value for the baseline constraint constant.
    // If the label is visible, it is animated immediately.
    public var baselineConstantWhenVisible: CGFloat = CGFloat(0.0) {
        didSet {
            if textFieldDidDrawRect {
                self.updateFloatingLabel()
            }
        }
    }

    // The label's color when visible, while its text field is being edited.
    // Setable in IB.
    // Defaults to the text field's tint color.
    @IBInspectable public var activeFloatingLabelColor: UIColor?

    // The label's color when visible, while its text field is not being edited.
    // Setable in IB.
    // Defaults to 70% gray (UITextField placeholder default color).
    @IBInspectable public var inactiveFloatingLabelColor: UIColor?

    // Returns whether the text field's floating label is visible or not.
    public var isFloatingLabelVisible: Bool {
        get {
            if let constraint = self.baselineConstraint {
                return constraint.constant != 0.0
            }
            return NO
        }
    }

    // Animation duration for showing/hiding the floating label.
    public var floatingLabelAnimationDuration: Double = 0.3

    // Animation duration for changing the floating label's text color.
    public var floatingLabelColorTransitionDuration: Double = 0.1


    //
    // MARK:- Initialization and Setup
    //

    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func setValue(value: AnyObject?, forKeyPath keyPath: String) {
        super.setValue(value, forKeyPath: keyPath)

        // Watch for the IB outlets to arrive.
        if keyPath == "floatingLabel" || keyPath == "baselineConstraint" {
            self.outletsDidArrive()
        }
    }

    private func outletsDidArrive() {
        if let label = self.floatingLabel {
            if let constraint = self.baselineConstraint {

                // Grab the current constant value of the label's baseline constraint.
                // (Documentation specifies that the label should be drawn as visible in IB.)
                baselineConstantWhenVisible = constraint.constant

                // Set our placeholder to match the label's text.
                // (Documentation specifies that the label will be used as the text field's placeholder, overwriting any existing value.)
                self.placeholder = label.text

                // Set the floating label's initial state based on whether it should currently be visible or hidden.
                self.presentOrDismissFloatingLabel(animated: NO)
                self.adjustFloatingLabelColor(animated: NO)
            }
        }
    }

    override public var text: String! {
        didSet {
            // Detect text changes made in code.
            self.updateFloatingLabel()
        }
    }


    //
    // MARK:- Floating Label State and Animation
    //

    private func floatingLabelShouldBeVisible() -> Bool {
        // There are two requirements for the floating label to be visible:

        // First, we must have a placeholder string assigned.
        var hasPlaceholder: Bool = NO

        if let placeholder = self.placeholder {
            hasPlaceholder = count(placeholder) > 0
        }

        if !hasPlaceholder {
            if let placeholder = self.floatingLabel?.text {
                hasPlaceholder = count(placeholder) > 0
            }
        }

        if !hasPlaceholder {
            if let text = self.floatingLabel?.text {
                hasPlaceholder = count(text) > 0
            }
        }

        // Second, we must have text present.
        var hasText: Bool = NO

        if let text = self.text {
            hasText = count(text) > 0
        }

        return hasPlaceholder && hasText
    }

    private func presentOrDismissFloatingLabel(animated: Bool = YES) {
        if let superview = self.superview {
            if let label = self.floatingLabel {
                if let constraint = self.baselineConstraint {

                    // Allow text field's cursor animations to finish.
                    // (without this here, our animations interfere with the cursor's animations, causing unwanted side-effects)
                    superview.layoutIfNeeded()

                    var alpha: CGFloat

                    if self.floatingLabelShouldBeVisible() {
                        alpha = 1.0
                        constraint.constant = self.baselineConstantWhenVisible
                    }
                    else {
                        alpha = 0.0
                        constraint.constant = CGFloat(0.0)
                    }

                    if animated {
                        UIView.animateWithDuration(floatingLabelAnimationDuration,
                            delay: 0.0,
                            options: .BeginFromCurrentState | .AllowUserInteraction,
                            animations: {
                                label.alpha = alpha
                                superview.layoutIfNeeded()
                            }, completion: nil)
                    }
                    else {
                        label.alpha = alpha
                    }
                }
            }
        }
    }

    private let seventyPercentGrayColor: UIColor = UIColor(white: 0.7, alpha: 1.0)

    private func adjustFloatingLabelColor(animated: Bool = YES) {
        if !self.isFloatingLabelVisible {
            return
        }

        if let label = self.floatingLabel {
            var color = self.isFirstResponder() ? self.tintColor : self.seventyPercentGrayColor

            if self.isFirstResponder() {
                if let chosenColor = self.activeFloatingLabelColor {
                    color = chosenColor
                }
            }
            else {
                if let chosenColor = self.inactiveFloatingLabelColor {
                    color = chosenColor
                }
            }

            if animated {
                UIView.transitionWithView(label,
                    duration: floatingLabelColorTransitionDuration,
                    options: .TransitionCrossDissolve | .BeginFromCurrentState | .AllowUserInteraction,
                    animations: {
                        label.textColor = color
                    }, completion: nil)
            }
            else {
                label.textColor = color
            }
        }
    }


    //
    // MARK:- Text Field Events
    //

    public override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder = super.becomeFirstResponder()

        if didBecomeFirstResponder {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "textDidChange", name: UITextFieldTextDidChangeNotification, object: self)
            self.updateFloatingLabel()
        }

        return didBecomeFirstResponder
    }

    public override func resignFirstResponder() -> Bool {
        let didResignFirstResponder = super.resignFirstResponder()

        if didResignFirstResponder {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: self)
            self.updateFloatingLabel()
        }

        return didResignFirstResponder
    }

    internal func textDidChange() {
        self.updateFloatingLabel()
    }

    private func updateFloatingLabel() {
        self.presentOrDismissFloatingLabel()
        self.adjustFloatingLabelColor()
    }

    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        textFieldDidDrawRect = YES
    }
}
