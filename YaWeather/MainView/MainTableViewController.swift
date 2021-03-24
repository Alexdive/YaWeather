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
    
    var swapIndex: Int?
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
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
            activityIndicator.stopAnimating(navigationItem: self.navigationItem)
            refreshControl.endRefreshing()
            pressPlusButton()
        } else {
            getWeather()
        }
    }
    
    
    
    func getWeather() {
        activityIndicator.animateActivity(title: "Загрузка...", view: self.view, navigationItem: navigationItem)
        viewModel.getCityWeather(citiesArray: viewModel.cityNamesArray) { [weak self] (index, result) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateUI(result: result, index: index)
            }
        }
    }
    
    private func updateUI(result: Result<Weather, ApiError>, index: Int) {
        switch result {
        case .success(let weather):
            if isOffline {
                isOffline = false
                view.show(message: "Connection has been restored", backgroundColor: .systemGreen)
            }
            Storage.shared.cityWeather[index] = weather
            Storage.shared.cityWeather[index].name = self.viewModel.cityNamesArray[index].lowercased()
            
        case .failure(.networkFailure(let error)):
            isOffline = true
            view.show(message: error.localizedDescription)
        case .failure(.invalidData):
            view.show(message: "Wrong data received")
        case .failure(.invalidModel):
            view.show(message: "Wrong data received")
        }
        tableView.reloadData()
        activityIndicator.stopAnimating(navigationItem: self.navigationItem)
        refreshControl.endRefreshing()
    }
    
    @objc func pressPlusButton() {
        alertAddCity(name: "Добавить город", placeholder: "Введите название города") { city in
            self.viewModel.getCoordinateFrom(city: city) { [weak self] (coordinate, error) in
                guard let self = self else { return }
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
                            let alertOk = UIAlertAction(title: "Попробовать еще раз", style: .default) { action in
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
        
        configureNavBar()
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }
    }
    
    private func configureNavBar() {
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 24,
                                                      weight: .regular,
                                                      scale: .medium)
        let btnPlus = UIButton(type: .custom)
        btnPlus.setBackgroundImage(UIImage(systemName: "plus.circle.fill",
                                           withConfiguration: largeConfig),
                                   for: .normal)
        btnPlus.addTarget(self, action: #selector(pressPlusButton),
                          for: .touchUpInside)
        btnPlus.tintColor = .systemTeal
        
        let btnSearch = UIButton(type: .custom)
        btnSearch.setBackgroundImage(UIImage(systemName: "magnifyingglass.circle.fill",
                                             withConfiguration: largeConfig),
                                     for: .normal)
        btnSearch.addTarget(self, action: #selector(searchTap), for: .touchUpInside)
        btnSearch.tintColor = .systemTeal
        
        let stackview = UIStackView(arrangedSubviews: [btnSearch, btnPlus])
        stackview.distribution = .fillEqually
        stackview.axis = .horizontal
        stackview.alignment = .center
        stackview.spacing = 12
        
        let rightBarButton = UIBarButtonItem(customView: stackview)
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    @objc func searchTap() {
        presentSearchBar()
    }
    
    private func presentSearchBar() {
        if navigationItem.searchController == nil {
            navigationItem.searchController = searchController
            
        } else {
            navigationItem.searchController = nil
        }
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
    }
    
    private func setupSearchController() {
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Поиск"
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
   
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        Storage.shared.cityWeather.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        viewModel.cityNamesArray.swapAt(sourceIndexPath.row, destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

            return isFiltering ? filterCitiesArray.count : Storage.shared.cityWeather.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MainTableViewCell.id, for: indexPath) as? MainTableViewCell else { return UITableViewCell() }
        
        cell.configure(weather: isFiltering ? filterCitiesArray[indexPath.row] : Storage.shared.cityWeather[indexPath.row])
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            return .none
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive,
                                              title: nil) { (_, _, completionHandler) in
            if self.isFiltering {
                let editingRow = self.filterCitiesArray[indexPath.row]
                if let index = self.filterCitiesArray.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    self.filterCitiesArray.remove(at: index)
                }
                if let index = Storage.shared.cityWeather.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    Storage.shared.cityWeather.remove(at: index)
                }
            } else {
                let editingRow = Storage.shared.cityWeather[indexPath.row]
                if let index = Storage.shared.cityWeather.firstIndex(where: { $0.name.lowercased() == editingRow.name.lowercased() }){
                    Storage.shared.cityWeather.remove(at: index)
                }
                if let index = self.viewModel.cityNamesArray.firstIndex(where: { $0.lowercased() == editingRow.name.lowercased() }){
                    self.viewModel.cityNamesArray.remove(at: index)
                }
            }
            tableView.reloadData()
        }
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22,
                                                      weight: .regular,
                                                      scale: .medium)
        deleteAction.image = UIImage(systemName: "trash", withConfiguration: symbolConfig)?.tint(with: .red)
        deleteAction.backgroundColor = .white
      
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 6
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
            vc.weatherModel = filterCitiesArray[indexPath.row]
        } else {
            vc.weatherModel = Storage.shared.cityWeather[indexPath.row]
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

extension MainTableViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = Storage.shared.cityWeather[indexPath.row]
        swapIndex = indexPath.row
        return [ dragItem ]
    }
    
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        
        guard session.items.count == 1 else { return dropProposal }
        
        if tableView.hasActiveDrag {
            dropProposal = UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return dropProposal
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        if let index = swapIndex {
            viewModel.cityNamesArray.swapAt(index, destinationIndexPath.row)
        }
        
        _ = coordinator.session.loadObjects(ofClass: Weather.self) { items in
   
            var indexPaths = [IndexPath]()
            for (index, item) in items.enumerated() {
                let indexPath = IndexPath(row: destinationIndexPath.row + index, section: destinationIndexPath.section)
                Storage.shared.cityWeather.insert(item, at: indexPath.row)
                indexPaths.append(indexPath)
            }

            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }
}

