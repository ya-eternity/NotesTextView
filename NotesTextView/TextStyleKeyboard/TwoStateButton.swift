//
//  TwoStateButton.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

// This button has two states that are ON and OFF
// It can be used to show whether Bold style is active or not.

class TwoStateButton: UIButton {
    let activeBackgroundColor = UIColor.systemGray4
    let inactiveBackgroundColor = UIColor.systemGray6
    let activeTextColor = UIColor.label
    let inactiveTextColor = UIColor.secondaryLabel

    var isActive = false {
        didSet {
            backgroundColor = isActive ? activeBackgroundColor : inactiveBackgroundColor
            tintColor = isActive ? activeTextColor : inactiveTextColor
        }
    }
}
