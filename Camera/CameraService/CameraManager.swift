//
//  CameraManager.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import AVFoundation
import UIKit
import Photos
import CoreLocation

final class CameraManager: NSObject, CLLocationManagerDelegate {
    
    private var qrCodeFrameView: UIView?

    // MARK: Properties
    
    private var captureSession: AVCaptureSession!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var currentCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var rearCamera: AVCaptureDevice?
    private var currentCameraPosition: CameraPosition = .rear
    private var metadataOutput: AVCaptureMetadataOutput?
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private var zoomFactor: CGFloat = 1.0
    
    enum CameraPosition {
        case front
        case rear
    }
    
    // Блок обратного вызова для передачи последнего изображения
    var onPhotoCaptured: ((UIImage) -> Void)?
    // Блок обратного вызова для передачи QR-кода
    var onQRCodeDetected: ((String) -> Void)?
    // Блок обратного вызова для передачи текста лэйбла
    var onZoomLevelChanged: ((CGFloat) -> Void)?
    
    // MARK: Initializers
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: Camera Setup
    
    func setupCamera(in view: UIView) {
        captureSession = AVCaptureSession()
        photoOutput = AVCapturePhotoOutput()
        captureSession.beginConfiguration()
        
        if let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.rearCamera = rearCamera
            currentCamera = rearCamera
            try? configureInput(for: rearCamera)
        } else {
            print("Не удалось найти заднюю камеру")
            return
        }
        
        captureSession.addOutput(photoOutput)
        
        // Настройка для QR-кодов
        metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput!) {
            captureSession.addOutput(metadataOutput!)
            metadataOutput!.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput!.metadataObjectTypes = [.qr]
        } else {
            print("Не удалось добавить метаданные для QR-кодов")
        }
        
        captureSession.commitConfiguration()
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = CGRect(
            x: 0,
            y: view.safeAreaInsets.top + 140,
            width: view.bounds.width,
            height: view.bounds.height - 140 - 175 - view.safeAreaInsets.bottom
        )
        view.layer.insertSublayer(videoPreviewLayer, at: 0)
        
        // Настройка рамки для QR-кода
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
        
        // Добавление распознавателя жестов для управления зумом
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    private func configureInput(for camera: AVCaptureDevice) throws {
        let input = try AVCaptureDeviceInput(device: camera)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            print("Не удалось добавить входное устройство: \(camera.localizedName)")
        }
    }
    
    private func addLogoAndLocation(to image: UIImage, location: CLLocation?) -> UIImage? {
        guard let logo = UIImage(named: "AppIcon") else { return nil }
        
        let logoSize = CGSize(width: 120, height: 120)
        let logoOrigin = CGPoint(x: image.size.width - logoSize.width - 20,
                                 y: image.size.height - logoSize.height - 20)
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        
        if let location = location {
            let locationText = String(format: "Lat: %.4f, Long: %.4f", location.coordinate.latitude, location.coordinate.longitude)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
            let timeText = dateFormatter.string(from: location.timestamp)
            
            let fullText = "\(locationText)\nTime: \(timeText)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = fullText.size(withAttributes: attributes)
            let textRect = CGRect(x: 20, y: image.size.height - textSize.height - 40, width: textSize.width, height: textSize.height)
            
            fullText.draw(in: textRect, withAttributes: attributes)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: Camera Controls
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            print("Не удалось получить текущее входное устройство")
            return
        }
        captureSession.removeInput(currentInput)
        
        if currentCameraPosition == .rear {
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("Не удалось найти переднюю камеру")
                return
            }
            self.frontCamera = frontCamera
            currentCamera = frontCamera
            currentCameraPosition = .front
        } else {
            guard let rearCamera = rearCamera else {
                print("Не удалось найти заднюю камеру")
                return
            }
            currentCamera = rearCamera
            currentCameraPosition = .rear
        }
        
        try? configureInput(for: currentCamera!)
        captureSession.commitConfiguration()
    }
    
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    func toggleTorch(isOn: Bool) {
        guard let device = currentCamera, device.hasTorch else {
            print("Фонарик недоступен на этом устройстве")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Ошибка при настройке фонарика: \(error.localizedDescription)")
        }
    }
    
    func setZoomLevel(to factor: CGFloat) {
        guard let device = currentCamera else {
            print("Камера недоступна")
            return
        }
        
        do {
            try device.lockForConfiguration()
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let clampedFactor = min(maxZoomFactor, factor)
            device.videoZoomFactor = clampedFactor
            zoomFactor = clampedFactor
            onZoomLevelChanged?(clampedFactor)
            print("Уровень зума установлен на: \(clampedFactor)")
            device.unlockForConfiguration()
        } catch {
            print("Ошибка при установке уровня зума: \(error.localizedDescription)")
        }
    }
    
    @objc 
    private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        let maxZoomFactor: CGFloat = 9.0
        let minZoomFactor: CGFloat = 1.0
        
        let newZoomFactor = zoomFactor * gesture.scale
        let clampedZoomFactor = min(max(newZoomFactor, minZoomFactor), maxZoomFactor)
        
        setZoomLevel(to: clampedZoomFactor)
        
        gesture.scale = 1.0
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка при получении местоположения: \(error.localizedDescription)")
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Не удалось получить данные фотографии")
            return
        }
        
        // Добавляем логотип и геопозицию к фото
        let finalImage = addLogoAndLocation(to: image, location: currentLocation)
        
        if let finalImage = finalImage {
            // Сохраняем фото в галерею
            UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
            
            // Вызываем блок обратного вызова после сохранения
            onPhotoCaptured?(finalImage)
        } else {
            print("Не удалось добавить логотип и геопозицию к фото")
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension CameraManager: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                qrCodeFrameView?.frame = CGRect.zero
                print("Не удалось распознать QR-код")
                return
            }
            
            // Вибрация при успешном считывании QR-кода
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            onQRCodeDetected?(stringValue)
            
            // Отображаем рамку вокруг QR-кода
            qrCodeFrameView?.frame = videoPreviewLayer.transformedMetadataObject(for: readableObject)?.bounds ?? CGRect.zero
            
            // Скрываем рамку после небольшой задержки
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.qrCodeFrameView?.frame = CGRect.zero
            }
        } else {
            qrCodeFrameView?.frame = CGRect.zero
        }
    }
}
