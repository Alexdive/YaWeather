//
//  MainTableViewController.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import UIKit
import MapKit

class MainTableViewController: UIViewController {
    
    private lazy var filterCitiesArray: [Weather] = []
    
    var viewModel = MainTableViewViewModel()
    
    var isOffline = false {
        didSet {
            self.title = isOffline ? "YaWeather offline" : "YaWeather"
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(MainTableViewCell.self, forCellReuseIdentifier: MainTableViewCell.id)
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .systemTeal
        refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        return refreshControl
    }()
    
    private lazy var activityIndicator = ActivityIndicator.shared
    
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
        viewModel.setupCities {
            getWeather()
        }
        setupSearchController()
    }
    
    @objc func refresh() {
        if viewModel.cityNamesArray.isEmpty {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating(navigationItem: self.navigationItem)
                self.refreshControl.endRefreshing()
                self.pressPlusButton()
            }
        } else {
            getWeather()
        }
    }
    
    func getWeather() {
        activityIndicator.animateActivity(title: "Загрузка...", view: self.view, navigationItem: navigationItem)
        viewModel.getCityWeather(citiesArray: viewModel.cityNamesArray) { (index, weather) in
            
            Storage.shared.cityWeather[index] = weather
            Storage.shared.cityWeather[index].name = self.viewModel.cityNamesArray[index].lowercased()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating(navigationItem: self.navigationItem)
                self.refreshControl.endRefreshing()
            }
        }
        DispatchQueue.main.async {
            self.viewModel.errorMessage.bind { [unowned self] in
                if let message = $0 {
                    DispatchQueue.main.async {
                        self.view.show(message: message)
                        if message.contains(NSLocalizedString("offline",
                                                              comment: "").lowercased()) {
                            self.isOffline = true
                        }
                        self.activityIndicator.stopAnimating(navigationItem: self.navigationItem)
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    self.isOffline = false
                }
            }
        }
        self.viewModel.errorMessage = Box(nil)
    }
    
    @objc func pressPlusButton() {
        alertAddCity(name: "Добавить город", placeholder: "Введите название города") { (city) in
            self.viewModel.getCoordinateFrom(city: city) { (coordinate, error) in
                if let coordinate = coordinate, error == nil {
                    self.viewModel.cityNamesArray.append(city.lowercased())
                    Storage.shared.cityCoordinate.append(CityCoordinate(city: city.lowercased(),
                                                                        lon: coordinate.longitude,
                                                                        lat: coordinate.latitude))
                    var newCity = Weather()
                    newCity.name = city
                    Storage.shared.cityWeather.append(newCity)
                    self.getWeather()
                } else {
                    if let error = error {
                        if error.localizedDescription.contains(NSLocalizedString("offline",
                                                                                 comment: "").lowercased()) {
                            DispatchQueue.main.async {
                                self.view.show(message: error.localizedDescription)
                            }
                        } else {
                            let alertController = UIAlertController(title: "Город не найден",
                                                                    message: nil,
                                                                    preferredStyle: .alert)
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
        }
    }
    
    private func setupViews() {
        title = "YaWeather"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(pressPlusButton))
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
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
        if let text = searchController.searchBar.text {
            filterContentForSearchText(text)
        }
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
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: "Удалить") { (_, _, completionHandler) in
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
                if let index = self.viewModel.cityNamesArray.firstIndex(where: { $0.lowercased() == editingRow.name.lowercased() }){
                    self.viewModel.cityNamesArray.remove(at: index)
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DetailsViewController()
        if isFiltering {
            vc.weatherModel = filterCitiesArray[indexPath.section]
        } else {
            vc.weatherModel = Storage.shared.cityWeather[indexPath.section]
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension MainTableViewController {
    
    func alertAddCity(name: String, placeholder: String, completionHandler: @escaping(String) -> Void) {
        
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
