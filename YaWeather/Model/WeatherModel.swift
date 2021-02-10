//
//  WeatherModel.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation

struct WeatherModel: Decodable {
    let info: Info
    let fact: Fact
    let forecasts: [ForecastModel]
}

struct Info: Decodable {
    let url: String
}

struct Fact: Decodable {
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

struct ForecastModel: Decodable, Encodable {
    var date: String = ""
    var hours: [Hours]
}

struct Hours: Decodable, Encodable {
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
    var forecasts: [ForecastModel] = [ForecastModel]()
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
    
    init?(weatherData: WeatherModel) {
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
