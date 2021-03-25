//
//  WeatherModel.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation

struct WeatherData: Codable {
    let info: Info
    let fact: Fact
    let forecasts: [ForecastData]
}

struct Info: Codable {
    let url: String
}

struct Fact: Codable {
    let temp: Double
    let icon: String
    let condition: String
    let windSpeed: Double
    let pressureMm: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case icon
        case condition
        case windSpeed = "wind_speed"
        case pressureMm = "pressure_mm"
    }
}

struct ForecastData: Codable {
    var date: String = ""
    var hours: [Hours]
}

struct Hours: Codable {
    var hour: String = ""
    var temp: Int = 0
}


struct Weather: Codable {
    var name: String = "Город"
    var temperature: Double = 0.0
    var temperatureString: String {
        return String(format: "%.0f",temperature)
    }
    var conditionCode: String = ""
    var url: String = ""
    var condition: String = ""
    var pressureMm: Int = 0
    var windSpeed: Double = 0.0
    var forecasts: [ForecastData] = [ForecastData]()
    var date: String = ""
    var hour: String = ""
    var temp: Int = 0
    
    var conditionString: String {
        switch condition {
        case "clear" : return "Ясно"
        case "partly-cloudy" : return "малооблачно"
        case "cloudy" : return "облачно с прояснениями"
        case "overcast" : return "пасмурно"
        case "drizzle" : return "морось"
        case "light-rain" : return "небольшой дождь"
        case "rain" : return "дождь"
        case "moderate-rain" : return "умеренно сильный дождь"
        case "heavy-rain" : return "сильный дождь"
        case "continuous-heavy-rain" : return "длительный сильный дождь"
        case "showers" : return "ливень"
        case "wet-snow" : return "дождь со снегом"
        case "light-snow" : return "небольшой снег"
        case "snow" : return "снег"
        case "snow-showers" : return "снегопад"
        case "hail" : return "град"
        case "thunderstorm" : return "гроза"
        case "thunderstorm-with-rain" : return "дождь с грозой"
        case "thunderstorm-with-hail" : return "гроза с градом"
        default:
            return "Загрузка..."
        }
    }
    
    init?(weatherData: WeatherData) {
        temperature = weatherData.fact.temp
        conditionCode = weatherData.fact.icon
        url = weatherData.info.url
        condition = weatherData.fact.condition
        pressureMm = weatherData.fact.pressureMm
        windSpeed = weatherData.fact.windSpeed
        forecasts = weatherData.forecasts
    }
    
    init() {}
}

struct CityCoordinate: Codable {
    let city: String
    let lon: Double
    let lat: Double
}

extension Weather: _ObjectiveCBridgeable {
    
    typealias _ObjectiveCType = NSString
    
    init(fromObjectiveC source: _ObjectiveCType) {
        self.name = source as String
    }
    
    static func _unconditionallyBridgeFromObjectiveC(_ source: NSString?) -> Weather {
        self.init(fromObjectiveC: source ?? "")
    }
    
    func _bridgeToObjectiveC() -> NSString {
        return NSString(string: self.name)
    }
    
    static func _forceBridgeFromObjectiveC(_ source: NSString, result: inout Weather?) {
        result = Weather(fromObjectiveC: source)
    }
    
    static func _conditionallyBridgeFromObjectiveC(_ source: NSString, result: inout Weather?) -> Bool {
        _forceBridgeFromObjectiveC(source, result: &result)
        return true
    }
}
