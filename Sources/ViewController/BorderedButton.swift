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
	
	public override var isEnabled: Bool {
		didSet {
			super.isEnabled = isEnabled
			updateBorderColor()
		}
	}
	
	public override var isHighlighted: Bool {
		didSet {
			super.isHighlighted = isHighlighted
			updateBorderColor()
		}
	}
	
	public override var isSelected: Bool {
		didSet {
			super.isSelected = isSelected
			updateBorderColor()
		}
	}
	
	
	// MARK: - Colors
	
	public override func tintColorDidChange() {
		super.tintColorDidChange()
		setTitleColor(tintColor, for: UIControlState())
		setTitleColor(UIColor.white(), for: .highlighted)
		setTitleColor(UIColor.white(), for: .selected)
		setTitleColor(disabledTintColor, for: .disabled)
		updateBorderColor()
	}
	
	func updateBorderColor() {
		if isEnabled {
			if isHighlighted || isSelected {
				backgroundColor = tintColor
				layer.borderColor = tintColor.cgColor
			}
			else {
				backgroundColor = UIColor.white();
				layer.borderColor = tintColor.cgColor;
			}
		}
		else {
			backgroundColor = UIColor.white();
			layer.borderColor = disabledTintColor.cgColor;
		}
	}
	
	
	// MARK: - Sizing
	
	public override func intrinsicContentSize() -> CGSize {
		let size = super.intrinsicContentSize()
		return CGSize(width: max(size.width + 20, 100), height: max(size.height, 44))
	}
}

