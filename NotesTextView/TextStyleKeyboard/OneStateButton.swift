//
//  OneStateButton.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

// This button has only one state.
// It triggers the specified button everytime it is tapped.
// but when user keeps it pressed, it shows highlighted background.
// This button can be used for Changing the Text Indents.

class OneStateButton: UIButton {
    let activeBackgroundColor = UIColor.systemGray4
    let inactiveBackgroundColor = UIColor.systemGray6
    let activeTextColor = UIColor.label
    let inactiveTextColor = UIColor.secondaryLabel

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? activeBackgroundColor : inactiveBackgroundColor
            tintColor = isHighlighted ? activeTextColor : inactiveTextColor
        }
    }
}
