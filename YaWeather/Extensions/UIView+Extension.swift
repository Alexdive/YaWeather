//
//  UIView+Extension.swift
//  YaWeather
//
//  Created by Alex Permiakov on 3/15/21.
//

import Foundation
import UIKit

extension UIView {
    @discardableResult
    func constraintsToSuperview(insets: UIEdgeInsets = .zero, heightFromTop: CGFloat? = nil, heightFromBottom: CGFloat? = nil) -> [NSLayoutConstraint.Attribute: NSLayoutConstraint] {
        guard let superview = superview else { return [:] }
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint.Attribute: NSLayoutConstraint] =
            [.left: leftAnchor.constraint(equalTo: superview.leftAnchor, constant: insets.left),
             .right: rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -insets.right)]
        
        if let heightFromTop = heightFromTop {
            constraints[.height] = heightAnchor.constraint(equalToConstant: heightFromTop)
        } else {
            constraints[.bottom] = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        }
        if let heightFromBottom = heightFromBottom {
            constraints[.height] = heightAnchor.constraint(equalToConstant: heightFromBottom)
        } else {
            constraints[.top] = topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top)
        }
        NSLayoutConstraint.activate(constraints.compactMap { $0.value })
        return constraints
    }
}
