//
//  Storage.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation
import MobileCoreServices

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
            var arrayCoord: [CityCoordinate] = []
            for data in encodedData {
                do {
                    let coord = try decoder.decode(CityCoordinate.self, from: data)
                    arrayCoord.append(coord)
                } catch {
                    print("error")
                }
            }
            return arrayCoord
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
            var arrayWeather: [Weather] = []
            for data in encodedData {
                do {
                    let weather = try decoder.decode(Weather.self, from: data)
                    arrayWeather.append(weather)
                } catch {
                    print("error")
                }
            }
            return arrayWeather
        }
        set {
            let data = newValue.map { try? encoder.encode($0)}
            UserDefaults.standard.set(data, forKey: storageWeatherKey)
        }
    }
}
