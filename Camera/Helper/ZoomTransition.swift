//
//  ZoomTransition.swift
//  Camera
//
//  Created by Денис Королевский on 4/9/24.
//

import UIKit

enum ZoomTransitionMode {
    case present, dismiss
}

final class ZoomTransition: NSObject {
    
    private var zoomView = UIView()
    
    public var duration = 0.3
    public var transitionMode: ZoomTransitionMode = .present
    public var startingPoint = CGPoint.zero {
        didSet {
            zoomView.center = startingPoint
        }
    }
    
    private func frameForZoomView(size: CGSize, startPoint: CGPoint) -> CGRect {
        // Размер целевого вью
        let targetWidth = size.width
        let targetHeight = size.height
        
        // Положение по x и y
        let originX = startPoint.x - targetWidth / 2
        let originY = startPoint.y - targetHeight / 2
        
        return CGRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
    }
}

extension ZoomTransition: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if transitionMode == .present {
            if let presentedView = transitionContext.view(forKey: .to) {
                let viewCenter = presentedView.center
                let viewSize = presentedView.frame.size
                
                zoomView = UIView()
                zoomView.frame = frameForZoomView(size: viewSize, startPoint: startingPoint)
                zoomView.center = startingPoint
                zoomView.backgroundColor = .clear
                zoomView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                containerView.addSubview(zoomView)
                
                presentedView.center = startingPoint
                presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                containerView.addSubview(presentedView)
                
                UIView.animate(withDuration: duration) {
                    self.zoomView.transform = CGAffineTransform.identity
                    presentedView.transform = CGAffineTransform.identity
                    presentedView.center = viewCenter
                } completion: { success in
                    transitionContext.completeTransition(success)
                }
            }
        } else {
            if let returnedView = transitionContext.view(forKey: .from) {
                let viewSize = returnedView.frame.size
                
                zoomView.frame = frameForZoomView(size: viewSize, startPoint: startingPoint)
                zoomView.center = startingPoint
                
                UIView.animate(withDuration: duration) {
                    self.zoomView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                    returnedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                    returnedView.center = self.startingPoint
                } completion: { success in
                    returnedView.removeFromSuperview()
                    self.zoomView.removeFromSuperview()
                    
                    transitionContext.completeTransition(success)
                }
            }
        }
    }
    
    
}
