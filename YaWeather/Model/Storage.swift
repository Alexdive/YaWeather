//
//  Storage.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation
import CoreLocation

class Storage {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    static let shared = Storage()
    
    private let storageWeatherKey = "storageWeatherKey"
    private let coordinatesKey = "coordinatesKey"
    
    var cityCoordinate: [CityCoordinate] {
        get {
            guard let encodedData = UserDefaults.standard.array(forKey: coordinatesKey) as? [Data] else {
                return []
            }
            return encodedData.map { try! decoder.decode(CityCoordinate.self, from: $0)}
        }
        set {
            let data = newValue.map { try? encoder.encode($0)}
            UserDefaults.standard.set(data, forKey: coordinatesKey)
        }
    }
    
    var cityWeather: [Weather] {
        get {
            guard let encodedData = UserDefaults.standard.array(forKey: storageWeatherKey) as? [Data] else {
                return []
            }
            return encodedData.map { try! decoder.decode(Weather.self, from: $0)}
        }
        set {
            let data = newValue.map { try? encoder.encode($0)}
            UserDefaults.standard.set(data, forKey: storageWeatherKey)
        }
    }
}
