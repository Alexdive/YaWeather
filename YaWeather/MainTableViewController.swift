//
//  MainTableViewController.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import UIKit
import MapKit

class MainTableViewController: UIViewController {
    
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    
    private lazy var refreshControl = UIRefreshControl()
    
    private lazy var networkManager = NetworkWeatherManager()
    
    private lazy var activityIndicator = UIActivityIndicatorView()
 
    private lazy var filterCitiesArray: [Weather] = []
    
    var cityNamesArray = ["Москва", "Иркутск", "Владивосток", "Чита", "Новосибирск", "Сочи", "Пенза", "Томск", "Санкт-Петербург", "Тюмень"]
    
    private lazy var searchController = UISearchController(searchResultsController: nil)
    
    var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        setupCities()
        setupSearchController()
    }
    
    @objc func refresh(_ sender: AnyObject) {
        if cityNamesArray.isEmpty {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                self.pressPlusButton()
            }
        } else {
            getWeather()
        }
    }
    
    private func setupCities() {
        var storage = Storage.shared.cityWeather
        var coord = Storage.shared.cityCoordinate
        if storage.isEmpty {
            storage = Array(repeating: Weather(), count: cityNamesArray.count)
            for (index, city) in cityNamesArray.enumerated() {
                storage[index].name = cityNamesArray[index].lowercased()
                getCoordinateFrom(city: city, completion: { (coordinate, error) in
                    guard let coordinate = coordinate, error == nil else { return }
                    coord.append(CityCoordinate(city: city.lowercased(), lon: coordinate.longitude, lat: coordinate.latitude))
                })
            }
            getWeather()
        } else {
            cityNamesArray.removeAll()
            storage.forEach { cityNamesArray.append($0.name.lowercased()) }
            if coord.isEmpty {
                for city in cityNamesArray {
                    getCoordinateFrom(city: city, completion: { (coordinate, error) in
                        guard let coordinate = coordinate, error == nil else { return }
                        coord.append(CityCoordinate(city: city.lowercased(), lon: coordinate.longitude, lat: coordinate.latitude))
                    })
                }
            }
            getWeather()
        }
    }
    
    func getWeather() {
        activityIndicator.startAnimating()
        getCityWeather(citiesArray: cityNamesArray) { (index, weather) in

            Storage.shared.cityWeather[index] = weather
            Storage.shared.cityWeather[index].name = self.cityNamesArray[index].lowercased()

            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func getCityWeather(citiesArray: [String], completionHandler: @escaping(Int, Weather) -> Void) {
      
        for (index, city) in citiesArray.enumerated() {
            if  let coordinate = Storage.shared.cityCoordinate.first(where: { $0.city.lowercased() == city.lowercased() }) {
                self.networkManager.fetchWeather(latitude: coordinate.lat, longitude: coordinate.lon) { (weather) in
                        completionHandler(index, weather)
                }
            } else {
                getCoordinateFrom(city: city) { (coordinate, error) in
                    guard let coordinate = coordinate, error == nil else { return }
                    Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(), lon: coordinate.longitude, lat: coordinate.latitude))
                    self.networkManager.fetchWeather(latitude: coordinate.latitude, longitude: coordinate.longitude) { (weather) in
                        completionHandler(index, weather)
                    }
                }
            }
        }
    }
    
    func getCoordinateFrom(city: String, completion: @escaping(_ coordinate: CLLocationCoordinate2D?, _ error: Error?) -> () ) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = city
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            guard let response = response else { return }
            let center = CLLocationCoordinate2D(latitude: response.boundingRegion.center.latitude, longitude: response.boundingRegion.center.longitude)
            completion(center, error)
        }
    }
    
    @objc func pressPlusButton() {
        alertPlusCity(name: "Добавить город", placeholder: "Введите название города") { (city) in
            self.getCoordinateFrom(city: city) { (coordinate, error) in
                if let coordinate = coordinate, error == nil {
                    self.cityNamesArray.append(city.lowercased())
                    Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(), lon: coordinate.longitude, lat: coordinate.latitude))
                    var newCity = Weather()
                    newCity.name = city
                    Storage.shared.cityWeather.append(newCity)
                    self.getWeather()
                }
                else {
                    let alertController = UIAlertController(title: "Город не найден", message: nil, preferredStyle: .alert)
                    let alertOk = UIAlertAction(title: "Попробовать еще раз", style: .default) { (action) in
                        self.pressPlusButton()
                    }
                    let alertCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
                    
                    alertController.addAction(alertOk)
                    alertController.addAction(alertCancel)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func setupViews() {
        title = "YaWeather"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(pressPlusButton))
        view.addSubview(tableView)
        tableView.addSubview(activityIndicator)
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        refreshControl.tintColor = .systemTeal
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: MainTableViewCell.id)
    }
    
    private func setupSearchController() {
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

extension MainTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filterCitiesArray = Storage.shared.cityWeather.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
}

// MARK: - Table view data source
extension MainTableViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering {
            return filterCitiesArray.count
        }
        return Storage.shared.cityWeather.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.id, for: indexPath) as? MainTableViewCell else { return UITableViewCell() }
        
        var weather = Weather()
        
        if isFiltering {
            weather = filterCitiesArray[indexPath.section]
        } else {
            weather = Storage.shared.cityWeather[indexPath.section]
        }
        cell.configure(weather: weather)
        cell.layer.masksToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { (_, _, completionHandler) in
            
            if self.isFiltering {
                let editingRow = self.filterCitiesArray[indexPath.section]
                if let index = self.filterCitiesArray.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    self.filterCitiesArray.remove(at: index)
                }
                if let index = Storage.shared.cityWeather.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    Storage.shared.cityWeather.remove(at: index)
                }
            } else {
                let editingRow = Storage.shared.cityWeather[indexPath.section]
                if let index = Storage.shared.cityWeather.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    Storage.shared.cityWeather.remove(at: index)
                }
                if let index = self.cityNamesArray.firstIndex(where: { $0.lowercased() == editingRow.name.lowercased() }){
                    self.cityNamesArray.remove(at: index)
                }
            }
            tableView.reloadData()
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .zero
    }
}

extension MainTableViewController {
    
    func alertPlusCity(name: String, placeholder: String, completionHandler: @escaping(String) -> Void) {
        
        let alertController = UIAlertController(title: name, message: nil, preferredStyle: .alert)
        let alertOk = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let tftext = alertController.textFields?.first
            guard let text = tftext?.text else { return }
            completionHandler(text)
        }
        
        alertController.addTextField { (tf) in
            tf.placeholder = placeholder
        }
        
        let alertCancel = UIAlertAction(title: "Отмена", style: .default, handler: nil)
        
        alertController.addAction(alertOk)
        alertController.addAction(alertCancel)
        
        present(alertController, animated: true, completion: nil)
    }
}
