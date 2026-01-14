//
//  TextStyleView.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

class TextStyleView: UIView {
    let label = UILabel()

    let activeBackgroundColor = UIColor.systemGray4
    let inactiveBackgroundColor = UIColor.systemGray6
    let activeTextColor = UIColor.label
    let inactiveTextColor = UIColor.secondaryLabel

    let tapGesture = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(label)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8).isActive = true
        label.setContentCompressionResistancePriority(UILayoutPriority(250), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal)
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = widthAnchor.constraint(equalTo: label.widthAnchor, multiplier: 1, constant: 22)
        widthConstraint.priority = UILayoutPriority(750)
        widthConstraint.isActive = true
        addGestureRecognizer(tapGesture)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("StyleView: init(coder:) has not been implemented")
    }

    var isActive = false {
        didSet {
            backgroundColor = isActive ? activeBackgroundColor : inactiveBackgroundColor
            label.textColor = isActive ? activeTextColor : inactiveTextColor
        }
    }
}
