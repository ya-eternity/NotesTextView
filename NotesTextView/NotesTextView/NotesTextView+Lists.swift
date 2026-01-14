//
//  NotesTextView+Lists.swift
//  NotesTextView
//
//  Refactored to proper NSTextList usage
//

import UIKit

extension NotesTextView {

    // MARK: - List Type

    func getCurrentListType() -> ListType {
        let textLength = textStorage.length
        guard textLength > 0 else {
            return listType(from: typingAttributes[.paragraphStyle] as? NSParagraphStyle)
        }

        let nsString = textStorage.string as NSString
        if shouldUseTypingAttributesForList(textLength: textLength, string: nsString) {
            return listType(from: typingAttributes[.paragraphStyle] as? NSParagraphStyle)
        }

        let paragraphRanges = paragraphRangesForSelection(textLength: textLength)
        guard !paragraphRanges.isEmpty else {
            return listType(from: typingAttributes[.paragraphStyle] as? NSParagraphStyle)
        }

        var detectedType: ListType?
        for paragraphRange in paragraphRanges where paragraphRange.location < textLength {
            let paragraphStyle = textStorage.attribute(
                .paragraphStyle,
                at: paragraphRange.location,
                effectiveRange: nil
            ) as? NSParagraphStyle
            let listType = listType(from: paragraphStyle)
            if let detectedType, detectedType != listType {
                return .none
            }
            detectedType = listType
        }

        return detectedType ?? listType(from: typingAttributes[.paragraphStyle] as? NSParagraphStyle)
    }

    // MARK: - Toggle Actions

    @objc func toggleOrderedList() {
        saveCurrentStateAndRegisterForUndo()

        updateList(
            getCurrentListType() == .ordered ? nil : .ordered
        )

        updateVisualForKeyboard()
    }

    @objc func toggleUnorderedList() {
        saveCurrentStateAndRegisterForUndo()

        updateList(
            getCurrentListType() == .unordered ? nil : .unordered
        )

        updateVisualForKeyboard()
    }

    // MARK: - Core List Update

    private func updateList(_ type: ListType?) {
        let textLength = textStorage.length

        guard textLength > 0 else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.textLists = type.map { [createTextList(for: $0)] } ?? []
            paragraphStyle.headIndent = type == nil ? 0 : 24
            paragraphStyle.firstLineHeadIndent = 0
            typingAttributes[.paragraphStyle] = paragraphStyle
            return
        }

        let nsString = textStorage.string as NSString
        if shouldUseTypingAttributesForList(textLength: textLength, string: nsString) {
            let paragraphStyle =
                (typingAttributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy()
                as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()

            if let type {
                paragraphStyle.textLists = [createTextList(for: type)]
                if paragraphStyle.headIndent == 0 && paragraphStyle.firstLineHeadIndent == 0 {
                    paragraphStyle.headIndent = 24
                    paragraphStyle.firstLineHeadIndent = 0
                }
            } else {
                paragraphStyle.textLists = []
                paragraphStyle.headIndent = 0
                paragraphStyle.firstLineHeadIndent = 0
            }

            typingAttributes[.paragraphStyle] = paragraphStyle
            return
        }

        let paragraphRanges = paragraphRangesForSelection(textLength: textLength)
        guard !paragraphRanges.isEmpty else { return }

        let listToApply: NSTextList?
        if let type {
            listToApply = listForSelection(
                type: type,
                paragraphRanges: paragraphRanges,
                textLength: textLength
            )
        } else {
            listToApply = nil
        }

        textStorage.beginEditing()
        for paragraphRange in paragraphRanges where paragraphRange.location < textLength {
            let baseStyle =
                (textStorage.attribute(
                    .paragraphStyle,
                    at: paragraphRange.location,
                    effectiveRange: nil
                ) as? NSParagraphStyle)
                ?? NSParagraphStyle.default

            let paragraphStyle = baseStyle.mutableCopy() as! NSMutableParagraphStyle

            if let type {
                let hadList = !paragraphStyle.textLists.isEmpty
                if let listToApply {
                    paragraphStyle.textLists = [listToApply]
                } else {
                    paragraphStyle.textLists = [createTextList(for: type)]
                }
                if !hadList && paragraphStyle.headIndent == 0 && paragraphStyle.firstLineHeadIndent == 0 {
                    paragraphStyle.headIndent = 24
                    paragraphStyle.firstLineHeadIndent = 0
                }
            } else {
                paragraphStyle.textLists = []
                paragraphStyle.headIndent = 0
                paragraphStyle.firstLineHeadIndent = 0
            }

            textStorage.addAttribute(
                .paragraphStyle,
                value: paragraphStyle,
                range: paragraphRange
            )
        }
        textStorage.endEditing()

        if let selectionRange = clampedSelectionRange(textLength: textLength) {
            let safeLocation = min(selectionRange.location, textLength - 1)
            if let paragraphStyle = textStorage.attribute(
                .paragraphStyle,
                at: safeLocation,
                effectiveRange: nil
            ) as? NSParagraphStyle {
                typingAttributes[.paragraphStyle] = paragraphStyle
            }
        }
    }


    // MARK: - NSTextList Factory

    private func createTextList(for listType: ListType) -> NSTextList {
        switch listType {
        case .ordered:
            return NSTextList(markerFormat: orderedMarkerFormat(), options: 0)
        case .unordered:
            return NSTextList(markerFormat: .disc, options: 0)
        case .none:
            fatalError("Invalid list type")
        }
    }

    private func listType(from paragraphStyle: NSParagraphStyle?) -> ListType {
        guard let list = paragraphStyle?.textLists.first else { return .none }

        if list.markerFormat == .decimal {
            return .ordered
        }
        if list.markerFormat == .disc {
            return .unordered
        }

        let markerFormat = list.markerFormat.rawValue.lowercased()
        if markerFormat.contains("decimal") {
            return .ordered
        }
        if markerFormat.contains("disc") {
            return .unordered
        }

        return .none
    }

    private func listForSelection(
        type: ListType,
        paragraphRanges: [NSRange],
        textLength: Int
    ) -> NSTextList {
        for paragraphRange in paragraphRanges where paragraphRange.location < textLength {
            if let style = textStorage.attribute(
                .paragraphStyle,
                at: paragraphRange.location,
                effectiveRange: nil
            ) as? NSParagraphStyle {
                if listType(from: style) == type, let list = style.textLists.first {
                    return list
                }
            }
        }

        return createTextList(for: type)
    }

    private func orderedMarkerFormat() -> NSTextList.MarkerFormat {
        return NSTextList.MarkerFormat(rawValue: "{decimal}.")
    }

    private func paragraphRangesForSelection(textLength: Int) -> [NSRange] {
        guard let selectionRange = clampedSelectionRange(textLength: textLength) else { return [] }

        let nsString = textStorage.string as NSString
        let paragraphRange = nsString.paragraphRange(for: selectionRange)
        return paragraphRanges(in: paragraphRange, string: nsString)
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

    private func shouldUseTypingAttributesForList(textLength: Int, string: NSString) -> Bool {
        guard selectedRange.length == 0 else { return false }
        guard selectedRange.location >= textLength else { return false }
        return isTrailingNewline(textLength: textLength, string: string)
    }

    private func isTrailingNewline(textLength: Int, string: NSString) -> Bool {
        guard textLength > 0 else { return false }
        let lastChar = string.substring(with: NSRange(location: textLength - 1, length: 1))
        return lastChar.rangeOfCharacter(from: .newlines) != nil
    }
}
