//
//  CALayer+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/30.
//  Copyright © 2020 sy. All rights reserved.
//

import AVFoundation


extension CALayer {
    class func gifLayer(data: Data, animationBeginTime: CFTimeInterval = CACurrentMediaTime(), removeOnCompletion: Bool = true) -> CALayer? {
        guard let gifSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let frameCount = CGImageSourceGetCount(gifSource)
        var frames = [CGImage]()
        var frameDurations = [Double]()
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        // Fill arrays
        for index in 0..<frameCount {
            // get each frame and frame duration
            guard let frame = CGImageSourceCreateImageAtIndex(gifSource, index, nil) else {
                return nil
            }
            let frameDuration = CGImageSource.sourceGetDelayTime(gifSource, at: index) ?? 0.01
            
            frames.append(frame)
            frameDurations.append(frameDuration)
            
            if let size = CGImageSource.sourceGetDimension(gifSource, at: index) {
                width = max(size.width, width)
                height = max(size.height, height)
            }
        }
        
        
        // Calculate full duration
        let duration = frameDurations.reduce(0, +)
        var timeOffset: Double = 0
        var animationTimes: [Double] = []
        
        frameDurations.forEach({
            animationTimes.append(timeOffset / duration)
            timeOffset += $0
        })
        animationTimes.append(1)
        
        let gifAnimation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.contents))
        gifAnimation.values = frames
        gifAnimation.keyTimes = animationTimes as [NSNumber]
        gifAnimation.duration = duration
        gifAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        gifAnimation.repeatCount = Float.greatestFiniteMagnitude
        gifAnimation.fillMode = .forwards
        gifAnimation.beginTime = animationBeginTime
        gifAnimation.isRemovedOnCompletion = removeOnCompletion
        
        let gifLayer = CALayer()
        gifLayer.contentsGravity = .resizeAspect
        if width > 0 && height > 0 {
            gifLayer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        gifLayer.add(gifAnimation, forKey: #keyPath(CALayer.contents))
 
        return gifLayer
    }

    class func gifLayer(url: URL,animationBeginTime: CFTimeInterval = CACurrentMediaTime(), removeOnCompletion: Bool = true) -> CALayer? {
        if let gifData =  try? Data(contentsOf: url) {
            return gifLayer(data: gifData, animationBeginTime: animationBeginTime, removeOnCompletion: removeOnCompletion)
        }
        return nil
    }
    
    class func gifLayer(name: String, animationBeginTime: CFTimeInterval = CACurrentMediaTime(), removeOnCompletion: Bool = true) -> CALayer? {
        if let url = Bundle.main.url(forResource: name, withExtension: ".gif") {
            return gifLayer(url: url, animationBeginTime: animationBeginTime, removeOnCompletion: removeOnCompletion)
        }
        return nil
    }
    
}



extension CGImageSource {
    class func sourceGetDelayTime(_ source: CGImageSource, at index: Int) -> Double? {
        var frameDuration: Double?
        // Get dictionaries
        let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        
        guard let frameProperties = cfFrameProperties as? [String:AnyObject] else {
            return nil
        }
        
        guard let gifProperties  = frameProperties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject] else {
            return nil
        }
        
        // Get delay time
        if let unclampDelayTime =  gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
            frameDuration = unclampDelayTime.doubleValue
        } else {
            if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                frameDuration = delayTime.doubleValue
            }
        }
        
        if let _ = frameDuration {
            if frameDuration! < 0.011 {
                frameDuration! = 0.01
            }
        }
        
        return frameDuration
    }
    
    
    class func sourceGetDimension(_ source: CGImageSource, at index: Int) -> CGSize? {
        let cfFramePropertices = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        guard let framePropertices = cfFramePropertices as? [String:AnyObject] else  {
            return nil
        }
        if let w = framePropertices[kCGImagePropertyPixelWidth as String] as? NSNumber,
            let h = framePropertices[kCGImagePropertyPixelHeight as String] as? NSNumber {
            return CGSize(width: CGFloat(w.floatValue), height: CGFloat(h.floatValue))
        }
        return nil
    }
}
