//
//  BorderedButton.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 22/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit


/**
A bordered button which we need to create manually because ORKBorderedButton is not public.
*/
public class BorderedButton: UIButton {
	
	var disabledTintColor = UIColor(white: 0.0, alpha: 0.3)
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		customInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		customInit()
	}
	
	func customInit() {
		layer.borderWidth = 1.0
		layer.cornerRadius = 5.0
		tintColorDidChange()
	}
	
	
	// MARK: - Actions
	
	public override var enabled: Bool {
		didSet {
			super.enabled = enabled
			updateBorderColor()
		}
	}
	
	public override var highlighted: Bool {
		didSet {
			super.highlighted = highlighted
			updateBorderColor()
		}
	}
	
	public override var selected: Bool {
		didSet {
			super.selected = selected
			updateBorderColor()
		}
	}
	
	
	// MARK: - Colors
	
	public override func tintColorDidChange() {
		super.tintColorDidChange()
		setTitleColor(tintColor, forState: .Normal)
		setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
		setTitleColor(UIColor.whiteColor(), forState: .Selected)
		setTitleColor(disabledTintColor, forState: .Disabled)
		updateBorderColor()
	}
	
	func updateBorderColor() {
		if enabled {
			if highlighted || selected {
				backgroundColor = tintColor
				layer.borderColor = tintColor.CGColor
			}
			else {
				backgroundColor = UIColor.whiteColor();
				layer.borderColor = tintColor.CGColor;
			}
		}
		else {
			backgroundColor = UIColor.whiteColor();
			layer.borderColor = disabledTintColor.CGColor;
		}
	}
	
	
	// MARK: - Sizing
	
	public override func intrinsicContentSize() -> CGSize {
		let size = super.intrinsicContentSize()
		return CGSize(width: max(size.width + 20, 100), height: max(size.height, 44))
	}
}

