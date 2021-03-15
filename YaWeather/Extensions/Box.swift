//
//  Box.swift
//  YaWeather
//
//  Created by Alex Permiakov on 3/15/21.
//

import Foundation

class Box<T> {
    typealias Listener = (T) -> Void
  var listener: Listener?

  var value: T {
    didSet {
      listener?(value)
    }
  }

  init(_ value: T) {
    self.value = value
  }

  func bind(listener: Listener?) {
    self.listener = listener
    listener?(value)
  }
}
