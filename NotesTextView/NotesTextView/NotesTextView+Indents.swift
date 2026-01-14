//
//  NotesTextView+Indents.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

extension NotesTextView {
    private var listIndentBase: CGFloat { 24 }

    private func clampedSelectionRange(textLength: Int) -> NSRange? {
        guard selectedRange.location != NSNotFound, textLength > 0 else { return nil }

        if selectedRange.length == 0 {
            let safeLocation = min(selectedRange.location, textLength - 1)
            return NSRange(location: safeLocation, length: 0)
        }

        guard selectedRange.location < textLength else { return nil }
        let safeLength = min(selectedRange.length, textLength - selectedRange.location)
        return NSRange(location: selectedRange.location, length: safeLength)
    }

    private func shouldUseTypingAttributesForIndent(textLength: Int, string: NSString) -> Bool {
        guard selectedRange.length == 0 else { return false }
        guard selectedRange.location >= textLength else { return false }
        return isTrailingNewline(textLength: textLength, string: string)
    }

    private func isTrailingNewline(textLength: Int, string: NSString) -> Bool {
        guard textLength > 0 else { return false }
        let lastChar = string.substring(with: NSRange(location: textLength - 1, length: 1))
        return lastChar.rangeOfCharacter(from: .newlines) != nil
    }

    private func paragraphRanges(in range: NSRange, string: NSString) -> [NSRange] {
        var ranges: [NSRange] = []
        var location = range.location
        let end = NSMaxRange(range)

        while location < end {
            let paragraphRange = string.paragraphRange(for: NSRange(location: location, length: 0))
            ranges.append(paragraphRange)
            let nextLocation = NSMaxRange(paragraphRange)
            if nextLocation <= location { break }
            location = nextLocation
        }

        if ranges.isEmpty {
            ranges.append(range)
        }

        return ranges
    }

    private func updateIndent(for paragraphStyle: NSMutableParagraphStyle, delta: CGFloat) {
        let currentHeadIndent = paragraphStyle.headIndent
        let currentFirstLineIndent = paragraphStyle.firstLineHeadIndent
        let indentDelta = currentFirstLineIndent - currentHeadIndent

        let updatedHeadIndent = min(max(currentHeadIndent + delta, minimumIndent), maximumIndent)
        let updatedFirstLineIndent = max(minimumIndent, updatedHeadIndent + indentDelta)

        paragraphStyle.headIndent = updatedHeadIndent
        paragraphStyle.firstLineHeadIndent = updatedFirstLineIndent
    }

    private func updateListIndent(for paragraphStyle: NSMutableParagraphStyle) {
        let listCount = paragraphStyle.textLists.count
        if listCount == 0 {
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
            return
        }
        paragraphStyle.headIndent = listIndentBase * CGFloat(listCount)
        paragraphStyle.firstLineHeadIndent = 0
    }

    private func adjustListNesting(
        for paragraphStyle: NSMutableParagraphStyle,
        delta: Int,
        listProvider: ((NSTextList.MarkerFormat) -> NSTextList)? = nil
    ) -> Bool {
        guard !paragraphStyle.textLists.isEmpty else { return false }

        var lists = paragraphStyle.textLists
        if delta > 0 {
            let markerFormat = lists.last?.markerFormat ?? lists.first!.markerFormat
            guard let listProvider else { return false }
            lists.append(listProvider(markerFormat))
        } else if delta < 0 {
            lists.removeLast()
        }
        paragraphStyle.textLists = lists
        updateListIndent(for: paragraphStyle)
        return true
    }

    func getCurrentIndent() -> CGFloat {
        let coreString = textStorage.string as NSString

        if shouldUseTypingAttributesForIndent(textLength: textStorage.length, string: coreString) {
            if let paraStyle = typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                return paraStyle.headIndent
            }
            return minimumIndent
        }

        let paraGraphRange = coreString.paragraphRange(for: selectedRange)

        let paraString = coreString.substring(with: paraGraphRange)
        guard !paraString.isEmpty else {
            if let paraStyle = typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                return paraStyle.headIndent
            } else {
                return minimumIndent
            }
        }

        let currentAttributes = textStorage.attributes(at: paraGraphRange.location, effectiveRange: nil)

        if let paraStyle = currentAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
            return paraStyle.headIndent
        } else {
            return minimumIndent
        }
    }

    @objc func indentLeft() {
        saveCurrentStateAndRegisterForUndo()

        let textLength = textStorage.length
        if textLength == 0 {
            let paraStyle =
                (typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)?
                    .mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            if !adjustListNesting(for: paraStyle, delta: -1) {
                updateIndent(for: paraStyle, delta: -indentWidth)
            }
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            updateVisualForKeyboard()
            return
        }

        let coreString = textStorage.string as NSString
        if shouldUseTypingAttributesForIndent(textLength: textLength, string: coreString) {
            let paraStyle =
                (typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)?
                    .mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            if !adjustListNesting(for: paraStyle, delta: -1) {
                updateIndent(for: paraStyle, delta: -indentWidth)
            }
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            updateVisualForKeyboard()
            return
        }
        guard let selectionRange = clampedSelectionRange(textLength: textLength) else { return }

        let paraGraphRange = coreString.paragraphRange(for: selectionRange)
        let paraString = coreString.substring(with: paraGraphRange)
        guard !paraString.isEmpty else {
            if let paraStyle = typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                let modifiedPara = paraStyle.mutableCopy() as! NSMutableParagraphStyle
                if !adjustListNesting(for: modifiedPara, delta: -1) {
                    updateIndent(for: modifiedPara, delta: -indentWidth)
                }
                typingAttributes[NSAttributedString.Key.paragraphStyle] = modifiedPara
            } else {
                let paraStyle = NSMutableParagraphStyle()
                if !adjustListNesting(for: paraStyle, delta: -1) {
                    updateIndent(for: paraStyle, delta: -indentWidth)
                }
                typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            }

            updateVisualForKeyboard()
            return
        }

        let paragraphRanges = paragraphRanges(in: paraGraphRange, string: coreString)
        var firstModifiedRange: NSRange?
        textStorage.beginEditing()
        for range in paragraphRanges where range.location < textLength {
            let currentAttributes = textStorage.attributes(at: range.location, effectiveRange: nil)
            let baseStyle =
                (currentAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)
                ?? NSParagraphStyle.default
            let modifiedPara = baseStyle.mutableCopy() as! NSMutableParagraphStyle
            if !adjustListNesting(for: modifiedPara, delta: -1) {
                updateIndent(for: modifiedPara, delta: -indentWidth)
            }
            textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: modifiedPara, range: range)
            if firstModifiedRange == nil {
                firstModifiedRange = range
            }
        }
        textStorage.endEditing()

        let targetRange = firstModifiedRange ?? paragraphRanges.first
        if let targetRange,
           targetRange.location < textLength,
           let paraStyle = textStorage.attribute(
            NSAttributedString.Key.paragraphStyle,
            at: targetRange.location,
            effectiveRange: nil
           ) as? NSParagraphStyle {
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
        }

        updateVisualForKeyboard()
    }

    @objc func indentRight() {
        saveCurrentStateAndRegisterForUndo()

        var listCache: [String: NSTextList] = [:]
        let listProvider: (NSTextList.MarkerFormat) -> NSTextList = { markerFormat in
            let key = markerFormat.rawValue
            if let cached = listCache[key] {
                return cached
            }
            let list = NSTextList(markerFormat: markerFormat, options: 0)
            listCache[key] = list
            return list
        }

        let textLength = textStorage.length
        if textLength == 0 {
            let paraStyle =
                (typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)?
                    .mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            if !adjustListNesting(for: paraStyle, delta: 1, listProvider: listProvider) {
                updateIndent(for: paraStyle, delta: indentWidth)
            }
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            updateVisualForKeyboard()
            return
        }

        let coreString = textStorage.string as NSString
        if shouldUseTypingAttributesForIndent(textLength: textLength, string: coreString) {
            let paraStyle =
                (typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)?
                    .mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            if !adjustListNesting(for: paraStyle, delta: 1, listProvider: listProvider) {
                updateIndent(for: paraStyle, delta: indentWidth)
            }
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            updateVisualForKeyboard()
            return
        }
        guard let selectionRange = clampedSelectionRange(textLength: textLength) else { return }

        let paraGraphRange = coreString.paragraphRange(for: selectionRange)
        let paraString = coreString.substring(with: paraGraphRange)
        guard !paraString.isEmpty else {
            if let paraStyle = typingAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                let modifiedPara = paraStyle.mutableCopy() as! NSMutableParagraphStyle
                if !adjustListNesting(for: modifiedPara, delta: 1, listProvider: listProvider) {
                    updateIndent(for: modifiedPara, delta: indentWidth)
                }
                typingAttributes[NSAttributedString.Key.paragraphStyle] = modifiedPara
            } else {
                let paraStyle = NSMutableParagraphStyle()
                if !adjustListNesting(for: paraStyle, delta: 1, listProvider: listProvider) {
                    updateIndent(for: paraStyle, delta: indentWidth)
                }
                typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
            }

            updateVisualForKeyboard()
            return
        }

        let paragraphRanges = paragraphRanges(in: paraGraphRange, string: coreString)
        var firstModifiedRange: NSRange?
        textStorage.beginEditing()
        for range in paragraphRanges where range.location < textLength {
            let currentAttributes = textStorage.attributes(at: range.location, effectiveRange: nil)
            let baseStyle =
                (currentAttributes[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle)
                ?? NSParagraphStyle.default
            let modifiedPara = baseStyle.mutableCopy() as! NSMutableParagraphStyle
            if !adjustListNesting(for: modifiedPara, delta: 1, listProvider: listProvider) {
                updateIndent(for: modifiedPara, delta: indentWidth)
            }
            textStorage.addAttribute(NSAttributedString.Key.paragraphStyle, value: modifiedPara, range: range)
            if firstModifiedRange == nil {
                firstModifiedRange = range
            }
        }
        textStorage.endEditing()

        let targetRange = firstModifiedRange ?? paragraphRanges.first
        if let targetRange,
           targetRange.location < textLength,
           let paraStyle = textStorage.attribute(
            NSAttributedString.Key.paragraphStyle,
            at: targetRange.location,
            effectiveRange: nil
           ) as? NSParagraphStyle {
            typingAttributes[NSAttributedString.Key.paragraphStyle] = paraStyle
        }

        updateVisualForKeyboard()
    }
}
