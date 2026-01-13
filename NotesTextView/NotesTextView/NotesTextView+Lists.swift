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
        guard selectedRange.location < textStorage.length,
              let style = textStorage.attribute(
                .paragraphStyle,
                at: selectedRange.location,
                effectiveRange: nil
              ) as? NSParagraphStyle,
              let list = style.textLists.first
        else {
            return .none
        }

        switch list.markerFormat {
        case .decimal:
            return .ordered
        case .disc:
            return .unordered
        default:
            return .none
        }
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
        let safeLocation = min(selectedRange.location, textLength - 1)
        let paragraphRange = nsString.paragraphRange(
            for: NSRange(location: safeLocation, length: 0)
        )

        guard paragraphRange.location < textLength else { return }

        let baseStyle =
            (textStorage.attribute(
                .paragraphStyle,
                at: paragraphRange.location,
                effectiveRange: nil
            ) as? NSParagraphStyle)
            ?? NSParagraphStyle.default

        let paragraphStyle = baseStyle.mutableCopy() as! NSMutableParagraphStyle

        if let type {
            paragraphStyle.textLists = [createTextList(for: type)]
            paragraphStyle.headIndent = 24
            paragraphStyle.firstLineHeadIndent = 0
        } else {
            paragraphStyle.textLists = []
            paragraphStyle.headIndent = 0
            paragraphStyle.firstLineHeadIndent = 0
        }

        textStorage.beginEditing()
        textStorage.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: paragraphRange
        )
        textStorage.endEditing()

        typingAttributes[.paragraphStyle] = paragraphStyle
    }


    // MARK: - NSTextList Factory

    private func createTextList(for listType: ListType) -> NSTextList {
        switch listType {
        case .ordered:
            return NSTextList(markerFormat: .decimal, options: 0)
        case .unordered:
            return NSTextList(markerFormat: .disc, options: 0)
        case .none:
            fatalError("Invalid list type")
        }
    }
}
