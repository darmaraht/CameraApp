//
//  PhotoCell.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import UIKit
import SnapKit

final class PhotoCell: UICollectionViewCell {
    
    // MARK: Subviews
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private(set) var currentAssetIdentifier: String?
    
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
        contentView.addSubview(imageView)
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
        
    func configure(with image: UIImage, assetIdentifier: String) {
        currentAssetIdentifier = assetIdentifier
        imageView.image = image
    }
        
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        currentAssetIdentifier = nil
    }
}
