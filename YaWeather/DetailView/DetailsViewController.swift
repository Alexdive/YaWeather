//
//  DetailsViewController.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/9/21.
//

import UIKit
import SwiftSVG

let imageCache = NSCache<NSString, CALayer>()

class DetailsViewController: UIViewController {
    
    var weatherModel: Weather?
    
    var forecastDay: ForecastData?
    
    private lazy var nameCityLabel: UILabel  = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 36, weight: .regular), textColor: .black, numberOfLines: 1, text: "")
        return label
    }()
    
    private lazy var weatherPic = UIView()
    
    private lazy var conditionLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 18, weight: .light), textColor: .black, numberOfLines: 2, text: "")
        return label
    }()
    
    private lazy var tempLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 26, weight: .regular), textColor: .black, numberOfLines: 1, text: "")
        return label
    }()
    
    private lazy var pressureLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 18, weight: .light), textColor: .black, numberOfLines: 2, text: "")
        return label
    }()
    
    private lazy var windLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 18, weight: .light), textColor: .black, numberOfLines: 2, text: "")
        return label
    }()
    
    private lazy var hoursCV: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let cv = UICollectionView(frame: view.safeAreaLayoutGuide.layoutFrame, collectionViewLayout: layout)
        cv.register(ForecastHoursCollectionViewCell.self, forCellWithReuseIdentifier: ForecastHoursCollectionViewCell.id)
        cv.backgroundColor = .white
        cv.showsHorizontalScrollIndicator = false
        cv.layer.borderWidth = 1
        cv.layer.borderColor = UIColor.systemGray3.cgColor
        cv.delegate = self
        cv.dataSource = self
        return cv
    }()
    
    private lazy var daysSwitch: UISegmentedControl = {
        let items = ["Сегодня", "Завтра"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.layer.cornerRadius = 5.0
        sc.layer.borderColor = UIColor.systemGray3.cgColor
        sc.layer.borderWidth = 1
        sc.backgroundColor = .systemTeal
        sc.addTarget(self, action: #selector(changeDate(sender:)), for: .valueChanged)
        return sc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let weatherModel = weatherModel {
            configure(weather: weatherModel)
        }
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let hour = Calendar.current.component(.hour, from: Date())
        hoursCV.layoutIfNeeded()
        hoursCV.scrollToItem(
            at: IndexPath(item: hour, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
    }
    
    @objc func changeDate(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            forecastDay = weatherModel?.forecasts[0]
            hoursCV.reloadData()
        case 1:
            forecastDay = weatherModel?.forecasts[1]
            hoursCV.reloadData()
        default:
            return
        }
    }
    
    func configure(weather: Weather) {
        forecastDay = weather.forecasts[0]
        nameCityLabel.text = weather.name.capitalized
        conditionLabel.text = weather.conditionString
        tempLabel.text = weather.temperatureString + "ºC"
        pressureLabel.text = "Давление \(weather.pressureMm) мм рт.ст."
        windLabel.text = "Скорость ветра \(weather.windSpeed) м/с"
        
        let urlString = "https://yastatic.net/weather/i/icons/blueye/color/svg/\(weather.conditionCode).svg"
        guard let url = URL(string: urlString) else { return }
        
        if let imageFromCache = imageCache.object(forKey: urlString as NSString) {
            self.weatherPic.layer.addSublayer(imageFromCache)
        } else {
            _ = CALayer(SVGURL: url) { [weak self] image in
                guard let self = self else { return }
                image.resizeToFit(self.weatherPic.bounds)
                self.weatherPic.layer.addSublayer(image)
                imageCache.setObject(image, forKey: urlString as NSString)
            }
        }
        view.layoutIfNeeded()
    }
    
    private func setupViews() {
        title = "Детальный прогноз"
        view.backgroundColor = .white
        weatherPic.contentMode = .center
        
        [nameCityLabel, weatherPic, conditionLabel, tempLabel, pressureLabel, windLabel, daysSwitch, hoursCV].forEach { view.addSubview($0) }
        
        nameCityLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            $0.centerX.equalToSuperview()
        }
        weatherPic.snp.makeConstraints {
            $0.top.equalTo(nameCityLabel.snp.bottom)
            $0.centerX.equalToSuperview().offset(-6)
            $0.height.width.equalTo(90)
        }
        conditionLabel.snp.makeConstraints {
            $0.top.equalTo(weatherPic.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        tempLabel.snp.makeConstraints {
            $0.top.equalTo(conditionLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        pressureLabel.snp.makeConstraints {
            $0.top.equalTo(tempLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        windLabel.snp.makeConstraints {
            $0.top.equalTo(pressureLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }
        daysSwitch.snp.makeConstraints {
            $0.top.equalTo(windLabel.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().inset(10)
            $0.height.equalTo(24)
        }
        hoursCV.snp.makeConstraints {
            $0.top.equalTo(daysSwitch.snp.bottom).offset(12)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(100)
        }
    }
}

extension DetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let forecastDay = forecastDay else { return 0 }
        return forecastDay.hours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ForecastHoursCollectionViewCell.id, for: indexPath) as? ForecastHoursCollectionViewCell else { return UICollectionViewCell() }
        if let forecastDay = forecastDay {
            cell.nextDayHourLabel.text = forecastDay.hours[indexPath.item].hour + ":00"
            cell.nextDayTempLabel.text = String(forecastDay.hours[indexPath.item].temp) + "ºC"
        }
        return cell
    }
}

extension DetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 90, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
