//
//  FullscreenPhotoVC.swift
//  Camera
//
//  Created by Денис Королевский on 23/8/24.
//

import UIKit

final class FullscreenPhotoVC: UIViewController {
    
    // MARK: Properties
    
    var image: UIImage?
    
    private let imageView = UIImageView()
    
    // MARK: Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupImageView()
        displayImage()
        
        setupGestures()
    }
    
    // MARK: Setup methods
    
    private func setupImageView() {
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        view.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        view.addGestureRecognizer(panGesture)
    }
    
    private func displayImage() {
        imageView.image = image
    }
    
    @objc
    private func handleTap() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let currentScale = view.transform.a
        let newScale = currentScale * gesture.scale
        
        if newScale >= 1.0 && newScale <= 3.0 {
            view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        }
        
        gesture.scale = 1.0
    }
    
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        let translation = gesture.translation(in: view)
        var newTransform = view.transform.translatedBy(x: translation.x, y: translation.y)
        
        // Ограничение перемещения внутри границ экрана
        let scale = view.transform.a
        let scaledImageSize = CGSize(width: imageView.bounds.width * scale, height: imageView.bounds.height * scale)
        let screenSize = view.bounds.size
        
        // Вычисление предельных значений для перемещения
        let xOffset = max(0, (scaledImageSize.width - screenSize.width) / 2)
        let yOffset = max(0, (scaledImageSize.height - screenSize.height) / 2)
        
        var newXTranslation = newTransform.tx
        var newYTranslation = newTransform.ty
        
        // Ограничение по горизонтали
        newXTranslation = max(-xOffset, min(xOffset, newXTranslation))
        
        // Ограничение по вертикали
        newYTranslation = max(-yOffset, min(yOffset, newYTranslation))
        
        newTransform.tx = newXTranslation
        newTransform.ty = newYTranslation
        
        view.transform = newTransform
        gesture.setTranslation(.zero, in: view)
    }
}
