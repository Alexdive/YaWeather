//
//  NetworkManager.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import Foundation
import Alamofire

class NetworkManager {
    class func getInfo(lat: String, lon: String, completionHandler: @escaping (WeatherModel?, Error?) -> Void) {
        let header: HTTPHeaders = ["X-Yandex-API-Key": "fdd424ec-48e7-43f1-b2d1-16bd86d44357"]
        AF.request("https://api.weather.yandex.ru/v2/forecast?lat=\(lat)&lon=\(lon)&lang=ru_RU&limit=2&hours=true&extra=false",
                   method: .get,
                   parameters: nil,
                   encoding: URLEncoding.default,
                   headers: header).response { (responseData) in
            guard let data = responseData.data else { return }
            do {
                let weather = try JSONDecoder().decode(WeatherModel.self, from: data)
                completionHandler(weather, nil)
            } catch let error {
                completionHandler(nil, error)
            }
        }
    }
}
