//
//  UIViewNotificationExtension.swift
//  YaWeather
//
//  Created by Alex Permiakov on 3/15/21.
//

import Foundation
import Toast_Swift

extension UIView {

    func show(message: String,
              timeout: TimeInterval = 5,
              position: ToastPosition = .bottom,
              isQueueEnabled: Bool = false,
              backgroundColor: UIColor? = nil) {
        
        let attrMessage = NSMutableAttributedString(string: message, attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor.white])
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width - 32, height: 0))
        view.backgroundColor = backgroundColor ?? .red
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        let imageView = UIImageView(image: UIImage(systemName: "wifi.exclamationmark"))
        imageView.tintColor = .white
        let isOfflineMessage = attrMessage.string.lowercased().contains(NSLocalizedString("offline",
                                                                                          comment: "").lowercased())
        
        let imageViewLeftSpace: CGFloat = isOfflineMessage ? 20 + 16 : 0
        let bottom: CGFloat = 16

        if isOfflineMessage {
            imageView.contentMode = .left
            view.addSubview(imageView)
            imageView.constraintsToSuperview(insets: .init(top: 16, left: 16, bottom: bottom, right: 16))
        }

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attrMessage
        view.addSubview(label)
        let size = CGSize(width: view.bounds.width - 32 - 16 - imageViewLeftSpace, height: .greatestFiniteMagnitude)
        let textRect = attrMessage.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        view.bounds.size.height = 16 + ceil(textRect.size.height) + bottom
        label.constraintsToSuperview(insets: .init(top: 16, left: imageViewLeftSpace + 16, bottom: bottom, right: 16))

        ToastManager.shared.isQueueEnabled = isQueueEnabled
        showToast(view, duration: timeout, position: position)
    }
}
