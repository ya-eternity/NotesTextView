//
//  ViewController.swift
//  TextDemo
//
//  Created by Rimesh Jotaniya on 03/06/20.
//  Copyright © 2020 Rimesh Jotaniya. All rights reserved.
//

import NotesTextView
import UIKit

class ViewController: UIViewController {
    let textView = NotesTextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
        textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        // to adjust the content insets based on keyboard height
        textView.shouldAdjustInsetBasedOnKeyboardHeight = true

        // to support iPad
        textView.hostingViewController = self

        _ = textView.becomeFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let text = textView.attributedText else { return }
//        AirPrintDiscovery.pickPrinter(from: self) { printer in
//            guard let p = printer else { return }
//            print(p)
//        }
        printRichText(text)
    }
    
    func printRichText(_ attributedText: NSAttributedString, jobName: String = "Print Text") {
        guard UIPrintInteractionController.isPrintingAvailable else { return }

        let formatter = UISimpleTextPrintFormatter(attributedText: attributedText)
        formatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = jobName
        controller.printInfo = info
        controller.printFormatter = formatter
        controller.present(animated: true)
    }
}


final class AirPrintDiscovery {

    static func pickPrinter(from vc: UIViewController,
                            sourceView: UIView? = nil,
                            completion: @escaping (UIPrinter?) -> Void) {
        let picker = UIPrinterPickerController(initiallySelectedPrinter: nil)

        // iPad 推荐 anchor 到某个 view；iPhone 用 view.bounds 也行
        let rect = sourceView?.bounds ?? vc.view.bounds
        let inView = sourceView ?? vc.view!

        picker.present(from: rect, in: inView, animated: true) { controller, userDidSelect, error in
            if let error = error {
                print("UIPrinterPicker error: \(error)")
                completion(nil)
                return
            }
            completion(userDidSelect ? controller.selectedPrinter : nil)
        }
    }
}
