//
//  CameraVC.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import UIKit
import SnapKit
import AVFoundation
import Photos

final class CameraVC: UIViewController {
    
    // MARK: Subviews
    
    private let lightButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private let shutterButton = UIButton(type: .custom)
    private let switchCameraButton = UIButton(type: .system)
    private let lastPhotoButton = UIButton(type: .custom)
    private let zoomControl = UISegmentedControl(items: ["1X", "2X", "3X"])
    let zoomLabel = UILabel()
    
    // MARK: Properties
    
    private let cameraManager = CameraManager()
    private var isLightOn = false
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        configureCameraManager()
        loadLastPhoto()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        turnOffTorchIfNeeded()
    }
    
    // MARK: Setup UI
    
    private func setupUI() {
        setupLightButton()
        setupCloseButton()
        setupShutterButton()
        setupSwitchCameraButton()
        setupLastPhotoButton()
        setupZoomControl()
        setupZoomLabel()
    }
    
    private func setupLightButton() {
        view.addSubview(lightButton)
        lightButton.setImage(UIImage(systemName: "bolt"), for: .normal)
        lightButton.tintColor = .white
        lightButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.left.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(80)
        }
        lightButton.addTarget(self, action: #selector(lightButtonTapped), for: .touchUpInside)
    }
    
    private func setupCloseButton() {
        view.addSubview(closeButton)
        closeButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        closeButton.tintColor = .white
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            $0.right.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.width.height.equalTo(80)
        }
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupShutterButton() {
        view.addSubview(shutterButton)
        shutterButton.setImage(UIImage(named: "shutter2"), for: .normal)
        shutterButton.clipsToBounds = true
        shutterButton.layer.cornerRadius = 40
        shutterButton.contentMode = .scaleAspectFit
        shutterButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 80))
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(50)
            make.centerX.equalToSuperview()
        }
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
    }
    
    private func setupSwitchCameraButton() {
        view.addSubview(switchCameraButton)
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        let configuration = UIImage.SymbolConfiguration(pointSize: 33, weight: .regular)
        switchCameraButton.setPreferredSymbolConfiguration(configuration, forImageIn: .normal)
        switchCameraButton.tintColor = .white
        switchCameraButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 50, height: 50))
            make.left.equalTo(shutterButton.snp.right).offset(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(65)
        }
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
    }
    
    private func setupLastPhotoButton() {
        view.addSubview(lastPhotoButton)
        lastPhotoButton.clipsToBounds = true
        lastPhotoButton.layer.cornerRadius = 8
        lastPhotoButton.contentMode = .scaleAspectFit
        lastPhotoButton.backgroundColor = .white
        lastPhotoButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 58, height: 80))
            make.left.equalToSuperview().offset(50)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(50)
        }
        lastPhotoButton.addTarget(self, action: #selector(lastPhotoButtonTapped), for: .touchUpInside)
    }
    
    private func setupZoomControl() {
        view.addSubview(zoomControl)
        zoomControl.selectedSegmentIndex = 0
        zoomControl.backgroundColor = .clear
        zoomControl.tintColor = .clear
        zoomControl.layer.borderColor = UIColor.white.cgColor
        zoomControl.layer.borderWidth = 1
        zoomControl.snp.makeConstraints { make in
            make.bottom.equalTo(shutterButton.snp.top).offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(30)
        }
        updateZoomControlAttributes()
        zoomControl.addTarget(self, action: #selector(zoomChanged), for: .valueChanged)
    }
    
    private func setupZoomLabel() {
        zoomLabel.textAlignment = .center
        zoomLabel.textColor = .black
        zoomLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        zoomLabel.text = "1.0X"
        view.addSubview(zoomLabel)
        zoomLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalTo(zoomControl.snp.centerY)
        }
        zoomLabel.isHidden = true
    }
    
    // MARK: Private Methods
    
    private func configureCameraManager() {
        cameraManager.onPhotoCaptured = { [weak self] image in
            self?.updateLastPhotoButton(with: image)
        }
        cameraManager.onQRCodeDetected = { [weak self] code in
            self?.handleQRCode(code)
        }
        cameraManager.onZoomLevelChanged = { [weak self] zoomLevel in
            self?.updateZoomLabel(with: zoomLevel)
        }
        cameraManager.setupCamera(in: view)
    }
    
    private func updateZoomLabel(with zoomLevel: CGFloat) {
        DispatchQueue.main.async {
            self.zoomLabel.text = String(format: "%.1fX", zoomLevel)
        }
        
        zoomLabel.isHidden = zoomLevel <= 1.0
    }
    
    private func turnOffTorchIfNeeded() {
        guard let device = AVCaptureDevice.default(for: .video), isLightOn else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = .off
            isLightOn = false
            device.unlockForConfiguration()
        } catch {
            print("Error locking configuration: \(error)")
        }
    }
    
    private func updateZoomControlAttributes() {
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 16, weight: .bold)
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black.withAlphaComponent(0.5),
            .font: UIFont.systemFont(ofSize: 16)
        ]
        let segments = zoomControl.numberOfSegments
        for index in 0..<segments {
            let title = zoomControl.titleForSegment(at: index) ?? ""
            let attributes = (index == zoomControl.selectedSegmentIndex) ? selectedAttributes : normalAttributes
            let attributedTitle = NSAttributedString(string: title, attributes: attributes)
            zoomControl.setTitleTextAttributes(selectedAttributes, for: .selected)
            zoomControl.setTitleTextAttributes(normalAttributes, for: .normal)
            zoomControl.setTitle(attributedTitle.string, forSegmentAt: index)
        }
    }
    
    private func loadLastPhoto() {
        let targetSize = lastPhotoButton.bounds.size
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            if let asset = fetchResult.firstObject {
                let imageManager = PHImageManager.default()
                let imageRequestOptions = PHImageRequestOptions()
                imageRequestOptions.isSynchronous = true
                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: imageRequestOptions) { image, _ in
                    if let image = image {
                        DispatchQueue.main.async {
                            self.updateLastPhotoButton(with: image)
                        }
                    }
                }
            }
        }
    }
    
    private func updateLastPhotoButton(with image: UIImage) {
        DispatchQueue.main.async {
            self.lastPhotoButton.setImage(image, for: .normal)
        }
    }
    
    private func showFullscreenPhoto(with image: UIImage) {
        let fullscreenVC = FullscreenPhotoVC()
        fullscreenVC.modalPresentationStyle = .fullScreen
        fullscreenVC.image = image
        present(fullscreenVC, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @objc
    private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func lightButtonTapped() {
        isLightOn.toggle()
        cameraManager.toggleTorch(isOn: isLightOn)
        lightButton.setImage(UIImage(systemName: isLightOn ? "bolt.fill" : "bolt"), for: .normal)
        lightButton.tintColor = isLightOn ? .yellow : .white
    }
    
    @objc
    private func shutterButtonTapped() {
        cameraManager.capturePhoto(delegate: cameraManager)
    }
    
    @objc
    private func switchCameraButtonTapped() {
        cameraManager.switchCamera()
    }
    
    @objc
    private func zoomChanged(_ sender: UISegmentedControl) {
        let zoomLevels: [CGFloat] = [1.0, 2.0, 3.0]
        let selectedZoom = zoomLevels[sender.selectedSegmentIndex]
        cameraManager.setZoomLevel(to: selectedZoom)
        updateZoomControlAttributes()
    }
    
    @objc 
    private func lastPhotoButtonTapped() {
        if let image = lastPhotoButton.image(for: .normal) {
            showFullscreenPhoto(with: image)
        }
    }
    
    private func handleQRCode(_ code: String) {
        let alert = UIAlertController(title: "QR Code Detected", message: code, preferredStyle: .alert)
        if let url = URL(string: code), UIApplication.shared.canOpenURL(url) {
            alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { _ in
                UIApplication.shared.open(url)
            }))
        } else {
            alert.title = "Text Detected"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

