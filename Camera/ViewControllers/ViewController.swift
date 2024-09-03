//
//  ViewController.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import UIKit
import Photos
import SnapKit

class ViewController: UIViewController {
    
    // MARK: Subviews

    private var photoCollectionView: UICollectionView!
    
    // MARK: Properties

    private var photos: [PHAsset] = [] // Храним PHAsset, а не UIImage
    private var fetchResult: PHFetchResult<PHAsset>!
    private let imageManager = PHImageManager.default()
    private let fetchOptions = PHFetchOptions()
    private let imagesPerPage = 32
    private var currentPage = 0
    private var isLoading = false
    
    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupPhotoCollectionView()
        setupFetchOptions()
        requestPhotoLibraryAccess()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadPhotos() // Перезагружаем фотографии при каждом появлении экрана
    }
    
    // MARK: Setup UI
    
    private func setupPhotoCollectionView() {
        let layout = UICollectionViewFlowLayout()
        
        let numberOfColumns: CGFloat = 4
        let padding: CGFloat = 10
        let totalPadding = padding * (numberOfColumns + 1)
        
        let availableWidth = UIScreen.main.bounds.width - totalPadding
        let itemWidth = availableWidth / numberOfColumns
        let itemHeight = itemWidth
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        
        photoCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.addSubview(photoCollectionView)
        photoCollectionView.contentInset = UIEdgeInsets(top: .zero, left: padding, bottom: .zero, right: padding)
        photoCollectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        photoCollectionView.register(AddPhotoCell.self, forCellWithReuseIdentifier: "AddPhotoCell")
    }
    
    // MARK: Private Methods
    
    private func setupFetchOptions() {
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    }

    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .authorized, .limited:
                self.loadPhotos()
            case .denied, .restricted, .notDetermined:
                print("Access to photo library denied or restricted")
            @unknown default:
                fatalError("Unknown authorization status")
            }
        }
    }
    
    private func loadPhotos() {
        guard !isLoading else { return }
        isLoading = true
        
        fetchOptions.fetchLimit = imagesPerPage * (currentPage + 1)
        fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let dispatchGroup = DispatchGroup()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        fetchResult.enumerateObjects { [weak self] asset, index, stop in
            guard let self = self else { return }
            
            if index < self.imagesPerPage * self.currentPage {
                return
            }
            if index >= self.imagesPerPage * (self.currentPage + 1) {
                stop.pointee = true
                return
            }
            
            dispatchGroup.enter()
            self.imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: options) { image, _ in
                if image != nil {
                    self.photos.append(asset) // Сохраняем PHAsset
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.photoCollectionView.reloadData()
            self.currentPage += 1
            self.isLoading = false
        }
    }
    
    private func reloadPhotos() {
        photos.removeAll() // Сбрасываем текущие данные
        currentPage = 0
        loadPhotos() // Перезагружаем фотографии
    }
    
    private func requestFullSizeImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCell", for: indexPath) as! AddPhotoCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
            let asset = photos[indexPath.row - 1]
            let assetIdentifier = asset.localIdentifier
            
            // Устанавливаем placeholder или пустое изображение
            cell.configure(with: UIImage(), assetIdentifier: assetIdentifier)
            
            // Запрашиваем изображение асинхронно
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil) { [weak cell] image, _ in
                guard let cell = cell, let image = image, asset.localIdentifier == cell.currentAssetIdentifier else { return }
                cell.configure(with: image, assetIdentifier: assetIdentifier)
            }
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let cameraVC = CameraVC()
            cameraVC.modalPresentationStyle = .fullScreen
            present(cameraVC, animated: true, completion: nil)
        } else {
            let asset = photos[indexPath.row - 1]
            requestFullSizeImage(for: asset) { [weak self] image in
                guard let self = self, let image = image else { return }
                
                let fullscreenPhotoVC = FullscreenPhotoVC()
                fullscreenPhotoVC.image = image
                fullscreenPhotoVC.modalPresentationStyle = .fullScreen
                self.present(fullscreenPhotoVC, animated: true, completion: nil)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.size.height

        if offsetY > contentHeight - scrollViewHeight * 2 {
            loadPhotos()
        }
    }
    
}
