//
//  StickerTrackItem.swift
//  05_videoEditor
//
//  Created by sy on 2020/7/2.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import CoreMedia

class StickerTrackItem: TrackItem, StickerProvider {
    enum InAnimationType {
        case none
        case fadeIn
        case scaleUp
    }
    
    enum OutAnimationType {
        case none
        case fadeOut
        case scaleDown
    }
    
    enum LoopAnimationType {
        case none
        case rotationZ
        case rotationY
        case heartBeat
    }
    
    var image: UIImage?
    
    var inAnimationType: InAnimationType = .fadeIn
    
    var outAnimationType: OutAnimationType = .fadeOut
    
    var loopAnimationType: LoopAnimationType = .none
    
    var inAnimationDuration: CMTime = CMTime(seconds: 0.5, preferredTimescale: 30)
    
    var outAnimationDuration: CMTime = CMTime(seconds: 0.5, preferredTimescale: 30)
    
    var position: CGPoint = .zero
    
    var transform: CATransform3D?
    
    var contentMode: CALayerContentsGravity = .resizeAspect
        
    var opacity: Float = 1.0
    
    var cornerRadius: Float = 0
    
    var borderWidth: Float = 0
    
    var borderColor: UIColor?
    
    override init(resource: Resource) {
        fatalError("Can't create from resource")
    }
    
    init(name: String) {
        self.image = UIImage(named: name)
        super.init()
    }
    
    init(url: URL) {
        if let data =  try? Data(contentsOf: url) {
            self.image = UIImage(data: data)
        }
        super.init()
    }
    
    required init() {
        super.init()
    }
    
    func animationLayer(for renderSize: CGSize) -> CALayer {
        guard let image = self.image else {
            return CALayer()
        }
        
        let imageLayer = CALayer()
        
        imageLayer.contents = image.cgImage
        imageLayer.contentsScale = image.scale
        imageLayer.contentsGravity = self.contentMode
        
        imageLayer.bounds = CGRect(origin: .zero, size: image.size)
        imageLayer.position = self.position
     
        if let transform = self.transform {
            imageLayer.transform = transform
        }
        
        let rotate = CABasicAnimation(keyPath: "transform.rotation")
        rotate.byValue = Float.pi * 2
        rotate.duration = 6
        rotate.repeatCount = 1
        rotate.timeOffset = 4
        rotate.isRemovedOnCompletion = false
        imageLayer.add(rotate, forKey: nil)
        
        return imageLayer
    }
    
}
