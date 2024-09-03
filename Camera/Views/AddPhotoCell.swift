//
//  AddPhotoCell.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import UIKit
import SnapKit

final class AddPhotoCell: UICollectionViewCell {
    
    // MARK: Subviews
    
    private let shutterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "shutter")
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup Methods
    
    private func setupViews() {
        contentView.addSubview(shutterImageView)
    }
    
    private func setupConstraints() {
        shutterImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
