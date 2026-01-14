//
//  NotesTextView+TextFormat.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

private let minimumFontSize: CGFloat = 8
private let maximumFontSize: CGFloat = 72
private let fontSizeStep: CGFloat = 1

extension NotesTextView {
    private func changeTrait(trait: UIFontDescriptor.SymbolicTraits) {
        let initialFont: UIFont?

        if selectedRange.length == 0 {
            initialFont = typingAttributes[NSAttributedString.Key.font] as? UIFont
        } else {
            initialFont = textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
        }

        if let currentFont = initialFont {
            var currentTraits = currentFont.fontDescriptor.symbolicTraits

            // complement the current traits
            _ = currentTraits.contains(trait) ? currentTraits.remove(trait) : currentTraits.update(with: trait)

            if let changedFontDescriptor = currentFont.fontDescriptor.withSymbolicTraits(currentTraits) {
                let currentFontSize = currentFont.pointSize
                let updatedFont = UIFont(descriptor: changedFontDescriptor, size: currentFontSize)

                if selectedRange.length != 0 {
                    textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
                        textStorage.beginEditing()
                        textStorage.addAttribute(.font, value: updatedFont, range: range)
                        textStorage.endEditing()
                    }
                }

                typingAttributes[NSAttributedString.Key.font] = updatedFont
                updateVisualForKeyboard()
            }
        }
    }

    @objc func makeTextBold() {
        saveCurrentStateAndRegisterForUndo()
        changeTrait(trait: .traitBold)
    }

    @objc func makeTextItalics() {
        saveCurrentStateAndRegisterForUndo()
        changeTrait(trait: .traitItalic)
    }

    @objc func makeTextUnderline() {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        let underlineAttribute: Int?

        if selectedRange.length == 0 {
            underlineAttribute = typingAttributes[NSAttributedString.Key.underlineStyle] as? Int
        } else {
            underlineAttribute = textStorage.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) as? Int
        }

        if let underline = underlineAttribute, underline == NSUnderlineStyle.single.rawValue {
            if selectedRange.length != 0 {
                textStorage.enumerateAttribute(.underlineStyle, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
                    textStorage.beginEditing()
                    textStorage.removeAttribute(NSAttributedString.Key.underlineStyle, range: range)
                    textStorage.endEditing()
                }
            }

            typingAttributes.removeValue(forKey: NSAttributedString.Key.underlineStyle)

        } else {
            if selectedRange.length != 0 {
                textStorage.beginEditing()
                textStorage.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
                textStorage.endEditing()
            }

            typingAttributes[NSAttributedString.Key.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        updateVisualForKeyboard()
    }

    @objc func makeTextStrikethrough() {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        let strikeThroughAttribute: Int?

        if selectedRange.length == 0 {
            strikeThroughAttribute = typingAttributes[NSAttributedString.Key.strikethroughStyle] as? Int
        } else {
            strikeThroughAttribute = textStorage.attribute(.strikethroughStyle, at: selectedRange.location, effectiveRange: nil) as? Int
        }

        if let strikeThrough = strikeThroughAttribute, strikeThrough == NSUnderlineStyle.single.rawValue {
            if selectedRange.length != 0 {
                textStorage.enumerateAttribute(.strikethroughStyle, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
                    textStorage.beginEditing()
                    textStorage.removeAttribute(NSAttributedString.Key.strikethroughStyle, range: range)
                    textStorage.endEditing()
                }
            }

            typingAttributes.removeValue(forKey: NSAttributedString.Key.strikethroughStyle)

        } else {
            if selectedRange.length != 0 {
                textStorage.beginEditing()
                textStorage.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
                textStorage.endEditing()
            }

            typingAttributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }

        updateVisualForKeyboard()
    }

    @objc func increaseFontSize() {
        adjustFontSize(by: fontSizeStep)
    }

    @objc func decreaseFontSize() {
        adjustFontSize(by: -fontSizeStep)
    }

    @objc func showFontPicker() {
        if #available(iOS 13.0, *) {
            let config = UIFontPickerViewController.Configuration()
            config.includeFaces = false

            let fontPicker = UIFontPickerViewController(configuration: config)
            fontPicker.delegate = self

            if let currentFont = typingAttributes[.font] as? UIFont {
                fontPicker.selectedFontDescriptor = currentFont.fontDescriptor
            }

            if let viewController = hostingViewController ?? findViewController() {
                viewController.present(fontPicker, animated: true)
            }
        }
    }

    func applyFontDescriptor(_ descriptor: UIFontDescriptor) {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        let baseFont: UIFont? = {
            if selectedRange.length == 0 {
                return typingAttributes[.font] as? UIFont
            }
            return textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
        }()

        let baseSize = baseFont?.pointSize ?? NotesFontProvider.shared.bodyFont.pointSize
        let baseTraits = baseFont?.fontDescriptor.symbolicTraits ?? []
        let resolvedDescriptor = descriptor.withSymbolicTraits(baseTraits) ?? descriptor
        let updatedFont = UIFont(descriptor: resolvedDescriptor, size: baseSize)

        if selectedRange.length != 0 {
            textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { value, range, _ in
                let rangeFont = (value as? UIFont) ?? baseFont ?? NotesFontProvider.shared.bodyFont
                let rangeTraits = rangeFont.fontDescriptor.symbolicTraits
                let rangeDescriptor = descriptor.withSymbolicTraits(rangeTraits) ?? descriptor
                let appliedFont = UIFont(descriptor: rangeDescriptor, size: rangeFont.pointSize)

                textStorage.beginEditing()
                textStorage.addAttribute(.font, value: appliedFont, range: range)
                textStorage.endEditing()
            }
        }

        typingAttributes[.font] = updatedFont
        updateVisualForKeyboard()
    }

    private func adjustFontSize(by delta: CGFloat) {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        if selectedRange.length != 0 {
            textStorage.enumerateAttribute(.font, in: selectedRange, options: .longestEffectiveRangeNotRequired) { value, range, _ in
                let currentFont = (value as? UIFont) ?? NotesFontProvider.shared.bodyFont
                let adjustedSize = min(maximumFontSize, max(minimumFontSize, currentFont.pointSize + delta))
                let updatedFont = UIFont(descriptor: currentFont.fontDescriptor, size: adjustedSize)

                textStorage.beginEditing()
                textStorage.addAttribute(.font, value: updatedFont, range: range)
                textStorage.endEditing()
            }
        }

        let currentFont = (selectedRange.length == 0)
            ? (typingAttributes[.font] as? UIFont ?? NotesFontProvider.shared.bodyFont)
            : (textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont ?? NotesFontProvider.shared.bodyFont)

        let adjustedSize = min(maximumFontSize, max(minimumFontSize, currentFont.pointSize + delta))
        typingAttributes[.font] = UIFont(descriptor: currentFont.fontDescriptor, size: adjustedSize)

        updateVisualForKeyboard()
    }
}

@available(iOS 13.0, *)
extension NotesTextView: UIFontPickerViewControllerDelegate {
    public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
        guard let descriptor = viewController.selectedFontDescriptor else { return }
        applyFontDescriptor(descriptor)
    }

    public func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
        viewController.dismiss(animated: true)
    }
}
