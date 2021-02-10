//
//  ForecastHoursCollectionViewCell.swift
//  YaWeather
//
//  Created by Alex Permiakov on 2/10/21.
//

import UIKit

class ForecastHoursCollectionViewCell: UICollectionViewCell {
    
    static let id = "ForecastHoursCollectionViewCell"
    
    private lazy var backView: UIView = {
        let backView = UIView()
        backView.backgroundColor = .systemTeal
        backView.layer.cornerRadius = 12
        backView.layer.borderWidth = 1
        backView.layer.borderColor = UIColor.systemGray3.cgColor
        backView.layer.masksToBounds = true
        return backView
    }()
    
    lazy var nextDayHourLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 16, weight: .light), textColor: .black, numberOfLines: 1, text: "")
        label.sizeToFit()
        return label
    }()
    
    lazy var nextDayTempLabel: UILabel = {
        let label = UILabel()
        label.labelSettings(textAlignment: .left, font: UIFont.systemFont(ofSize: 20, weight: .regular), textColor: .black, numberOfLines: 1, text: "")
        label.sizeToFit()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        contentView.addSubview(backView)
        backView.addSubview(nextDayHourLabel)
        backView.addSubview(nextDayTempLabel)
        
        backView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        nextDayHourLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(25)
        }
        nextDayTempLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(25)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }
}
