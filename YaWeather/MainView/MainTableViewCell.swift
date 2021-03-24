//
//  MainTableViewCell.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/8/21.
//

import UIKit
import SnapKit

class MainTableViewCell: UITableViewCell {
    
    static let id = "MainTableViewCell"
    
    private lazy var backView = UIView()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 18, weight: .regular), textColor: .black, numberOfLines: 1, text: "")
        return label
    }()
    
    lazy var conditionLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .right, font: UIFont.systemFont(ofSize: 16, weight: .light), textColor: .black, numberOfLines: 2, text: "")
        return label
    }()
    
    private lazy var tempLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 18, weight: .regular), textColor: .black, numberOfLines: 1, text: "")
        return label
    }()
    
    private lazy var activityIndicator = UIActivityIndicatorView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        activityIndicator.startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(weather: Weather) {
        DispatchQueue.main.async {
            self.nameLabel.text = weather.name.capitalized
            self.conditionLabel.text = weather.conditionString
            self.tempLabel.text = weather.temperatureString + "ºC"
        }
    }
    
    private func setupView() {
        contentView.addSubview(backView)
        [nameLabel, conditionLabel, tempLabel, activityIndicator].forEach { backView.addSubview($0) }
        
        backgroundColor = .clear
        selectedBackgroundView?.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        backView.backgroundColor = .systemTeal
        backView.layer.cornerRadius = 12
        backView.layer.borderWidth = 1
        backView.layer.borderColor = UIColor.systemGray3.cgColor
        backView.layer.masksToBounds = true
       
        backView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(6)
        }
        nameLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(12)
        }
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        conditionLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(contentView.snp.centerX).offset(-16)
            $0.trailing.equalTo(contentView.snp.trailing).offset(-66)
        }
        tempLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(contentView.snp.trailing).offset(-12)
        }
    }
}
