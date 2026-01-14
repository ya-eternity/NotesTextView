//
//  NotesTextView+TextStyleKeyboardViewDelegate.swift
//  NotesTextView
//
//  Created by Rimesh Jotaniya on 29/05/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import UIKit

extension NotesTextView: TextStyleKeyboardViewDelegate {
    func didSelectTextColor(selectedColor: UIColor) {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        textStorage.enumerateAttribute(.foregroundColor, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
            textStorage.beginEditing()
            textStorage.addAttribute(.foregroundColor, value: selectedColor, range: range)
            textStorage.endEditing()
        }

        typingAttributes[.foregroundColor] = selectedColor
        updateVisualForKeyboard()
    }

    func didSelectHighlightColor(selectedColor: UIColor) {
        guard selectedRange.location != NSNotFound else { return }

        saveCurrentStateAndRegisterForUndo()

        if selectedColor == UIColor.clear {
            // we need to remove the background color

            if selectedRange.length != 0 {
                textStorage.enumerateAttribute(.backgroundColor, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
                    textStorage.beginEditing()
                    textStorage.removeAttribute(.backgroundColor, range: range)
                    textStorage.endEditing()
                }
            }

            typingAttributes[.backgroundColor] = selectedColor
            updateVisualForKeyboard()
        } else {
            // we need to add the background color

            if selectedRange.length != 0 {
                textStorage.enumerateAttribute(.backgroundColor, in: selectedRange, options: .longestEffectiveRangeNotRequired) { _, range, _ in
                    textStorage.beginEditing()
                    textStorage.addAttribute(.backgroundColor, value: selectedColor as Any, range: range)
                    textStorage.endEditing()
                }
            }

            typingAttributes[.backgroundColor] = selectedColor
            updateVisualForKeyboard()
        }
    }
    
    func didRequestSystemColorPicker(forTextColor: Bool) {
        if #available(iOS 14.0, *) {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            colorPicker.supportsAlpha = false
            
            // 设置当前选中的颜色
            if forTextColor {
                if let currentColor = typingAttributes[.foregroundColor] as? UIColor {
                    colorPicker.selectedColor = currentColor
                }
            } else {
                if let currentColor = typingAttributes[.backgroundColor] as? UIColor {
                    colorPicker.selectedColor = currentColor
                }
            }
            
            // 存储当前选择的是文字颜色还是背景色
            systemColorPickerForTextColor = forTextColor
            
            // 获取当前的 view controller 来呈现颜色选择器
            if let viewController = hostingViewController ?? findViewController() {
                viewController.present(colorPicker, animated: true)
            }
        }
    }
    
}

@available(iOS 14.0, *)
extension NotesTextView: UIColorPickerViewControllerDelegate {
    public func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        
        if systemColorPickerForTextColor {
            didSelectTextColor(selectedColor: selectedColor)
        } else {
            didSelectHighlightColor(selectedColor: selectedColor)
        }
    }
    
    public func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        viewController.dismiss(animated: true)
    }
}
