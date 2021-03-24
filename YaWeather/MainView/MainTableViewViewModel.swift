//
//  MainTableViewViewModel.swift
//  YaWeather
//
//  Created by Alex Permiakov on 3/15/21.
//

import Foundation
import MapKit

class MainTableViewViewModel {
    
    private lazy var networkManager = NetworkWeatherManager()
    
    var cityNamesArray = ["Москва", "Санкт-Петербург", "Иркутск", "Владивосток", "Новосибирск", "Сочи", "Пенза", "Томск", "Челябинск", "Тюмень"]
    
    func setupCities(completion: () -> Void) {
//        first launch of an app or when all cities have been deleted before exit
        if Storage.shared.cityWeather.isEmpty {
            Storage.shared.cityWeather = Array(repeating: Weather(), count: cityNamesArray.count)
            for (index, city) in cityNamesArray.enumerated() {
                Storage.shared.cityWeather[index].name = cityNamesArray[index].lowercased()
                getCoordinateFrom(city: city, completion: { (coordinate, error) in
                    guard let coordinate = coordinate, error == nil else { return }
                    Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(),
                                                                        lon: coordinate.longitude,
                                                                        lat: coordinate.latitude))
                })
            }
            completion()
        } else {
            cityNamesArray.removeAll()
            Storage.shared.cityWeather.forEach { cityNamesArray.append($0.name.lowercased()) }
            if Storage.shared.cityCoordinate.isEmpty {
                for city in cityNamesArray {
                    getCoordinateFrom(city: city, completion: { (coordinate, error) in
                        guard let coordinate = coordinate, error == nil else { return }
                        Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(),
                                                                            lon: coordinate.longitude,
                                                                            lat: coordinate.latitude))
                    })
                }
            }
            completion()
        }
    }
    
    func getCityWeather(citiesArray: [String], completionHandler: @escaping(Int, Result<Weather, ApiError>) -> Void) {
        
        for (index, city) in citiesArray.enumerated() {
            if let coordinate = Storage.shared.cityCoordinate.first(where: { $0.city.lowercased() == city.lowercased() }) {
                self.networkManager.fetchWeather(latitude: coordinate.lat,
                                                 longitude: coordinate.lon) { result in
                    completionHandler(index, result)
                }
            } else {
                getCoordinateFrom(city: city) { (coordinate, error) in
                    guard let coordinate = coordinate, error == nil else { return }
                    Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(),
                                                                        lon: coordinate.longitude,
                                                                        lat: coordinate.latitude))
                    self.networkManager.fetchWeather(latitude: coordinate.latitude,
                                                     longitude: coordinate.longitude) { result in
                        completionHandler(index, result)
                    }
                }
            }
        }
    }
    
    func getCoordinateFrom(city: String, completion: @escaping(_ coordinate: CLLocationCoordinate2D?,
                                                               _ error: Error?) -> () ) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = city
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            
            if let error = error {
                completion(nil, error)
            }
            
            guard let response = response else { return }
            let coordinate = CLLocationCoordinate2D(latitude: response.boundingRegion.center.latitude,
                                                longitude: response.boundingRegion.center.longitude)
            completion(coordinate, error)
        }
    }
    
}
