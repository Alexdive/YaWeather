//
//  NetworkManager.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation

class NetworkWeatherManager {
    
    let apiKey = "fabf95b9-ac15-4fb0-a5af-126a1b18216f"
    
    func fetchWeather(latitude: Double, longitude: Double, completionHandler: @escaping (Weather) -> Void ) {
        let stringUrl = "https://api.weather.yandex.ru/v2/forecast?lat=\(latitude)&lon=\(longitude)&lang=ru_RU&limit=2&hours=true&extra=false"
        guard let url = URL(string: stringUrl) else { return }
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        request.addValue(apiKey, forHTTPHeaderField: "X-Yandex-API-Key")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            if let error = error as NSError? {
                print(error.debugDescription)
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print(httpResponse.allHeaderFields)
                print(httpResponse.statusCode)
            }
            
            guard let data = data else {
                print(String(describing: error))
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let weather = self.parseJSON(withData: data) {
                    completionHandler(weather)
                }
            }
        }
        task.resume()
    }
    
    func parseJSON(withData data: Data) -> Weather? {
        let decoder = JSONDecoder()
        do {
            let weatherData = try decoder.decode(WeatherModel.self, from: data)
            guard let weather = Weather(weatherData: weatherData) else {
                return nil
            }
            return weather
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}
