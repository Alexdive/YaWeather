//
//  Storage.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation

class UD {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    static let shared = UD()
    
    private let recordWeatherModelKey = "weatherDataKey"
    
    var recordWeatherModel: [WeatherModel] {
        get {
            guard let encodedData = UserDefaults.standard.array(forKey: recordWeatherModelKey) as? [Data] else {
                return []
            }
            return encodedData.map { try! decoder.decode(WeatherModel.self, from: $0)}
        }
        set {
            let data = newValue.map { try? encoder.encode($0)}
            UserDefaults.standard.set(data, forKey: recordWeatherModelKey)
        }
    }
}
