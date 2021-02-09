//
//  UILabel+AppStyle.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/9/21.
//

import UIKit

extension UILabel {
    func labelSettings(textAlignment: NSTextAlignment, font: UIFont, textColor: UIColor, numberOfLines: Int, text: String) {
        self.textAlignment = textAlignment
        self.font = font
        self.textColor = textColor
        self.numberOfLines = numberOfLines
        self.text = text
        self.clipsToBounds = true
    }
}
