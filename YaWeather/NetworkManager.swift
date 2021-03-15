//
//  NetworkManager.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation

enum ApiError: Error {
    case networkFailure(Error)
    case invalidData
    case invalidModel
}

struct NetworkWeatherManager {
    
    let apiKey = "fabf95b9-ac15-4fb0-a5af-126a1b18216f"
    
    func fetchWeather(latitude: Double, longitude: Double, completionHandler: @escaping (Result<Weather, ApiError>) -> Void ) {
        let stringUrl = "https://api.weather.yandex.ru/v2/forecast?lat=\(latitude)&lon=\(longitude)&lang=ru_RU&limit=2&hours=true&extra=false"
        guard let url = URL(string: stringUrl) else {
            preconditionFailure("Check if URL is valid!")
        }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue(apiKey, forHTTPHeaderField: "X-Yandex-API-Key")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error as NSError? {
                print(error.debugDescription)
                completionHandler(.failure(.networkFailure(error)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.allHeaderFields)
                print(httpResponse.statusCode)
            }
            
            guard let data = data else {
                completionHandler(.failure(.invalidData))
                return
            }
            if let weather = try? parseJSON(withData: data) {
                completionHandler(.success(weather))
            } else {
                completionHandler(.failure(.invalidModel))
            }
        }
        task.resume()
    }
    
    func parseJSON(withData data: Data) throws -> Weather? {
        let decoder = JSONDecoder()
        do {
            let weatherData = try decoder.decode(WeatherData.self, from: data)
            guard let weather = Weather(weatherData: weatherData) else {
                throw ApiError.invalidModel
            }
            return weather
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        throw ApiError.invalidModel
    }
}
