//
//  UIImage+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/30.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

extension UIImage {
    public class func gif(data: Data) -> UIImage? {
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            #if DEBUG
            print("SwiftGif: Source for the image does not exist")
            #endif
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }
    
    public class func gif(url: URL) -> UIImage? {
        guard let imageData = try? Data(contentsOf: url) else {
            #if DEBUG
            print("SwiftGif: Cannot fetch image: \"\(url)\" into NSData")
            #endif
            return nil
        }
        
        return gif(data: imageData)
    }
    
    public class func gif(name: String) -> UIImage? {
        // Check for existance of gif
        guard let bundleURL = Bundle.main.url(forResource: name, withExtension: "gif") else {
            #if DEBUG
            print("SwiftGif: This image named \"\(name)\" does not exist")
            #endif
            return nil
        }
        
        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gif(data: imageData)
    }
    
    @available(iOS 9.0, *)
    public class func gif(asset: String) -> UIImage? {
        // Create source from assets catalog
        guard let dataAsset = NSDataAsset(name: asset) else {
            #if DEBUG
            print("SwiftGif: Cannot turn image named \"\(asset)\" into NSDataAsset")
            #endif
            return nil
        }
        
        return gif(data: dataAsset.data)
    }
    
    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double? {
        var delay: Double?
        // Get dictionaries
        let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        guard let frameProperties = cfFrameProperties as? [String:AnyObject] else {
            return nil
        }
        
        guard let gifProperties = frameProperties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject] else {
            return nil
        }
        
        if let unclampDelayTime =  gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
            delay = unclampDelayTime.doubleValue
        } else {
            if let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                delay = delayTime.doubleValue
            }
        }
        
        if let _ = delay {
            if delay! < 0.011 {
                delay! = 0.01
            }
        }
        
        return delay
    }
    
    internal class func gcdForPair(_ lhs: Int?, _ rhs: Int?) -> Int {
        var lhs = lhs
        var rhs = rhs
        // Check if one of them is nil
        if rhs == nil || lhs == nil {
            if rhs != nil {
                return rhs!
            } else if lhs != nil {
                return lhs!
            } else {
                return 0
            }
        }
        
        // Swap for modulo
        if lhs! < rhs! {
            let ctp = lhs
            lhs = rhs
            rhs = ctp
        }
        
        // Get greatest common divisor
        var rest: Int
        while true {
            rest = lhs! % rhs!
            
            if rest == 0 {
                return rhs! // Found it
            } else {
                lhs = rhs
                rhs = rest
            }
        }
    }
    
    internal class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        
        var frames = [CGImage]()
        var frameDurations = [Int]()

        
        // Fill arrays
        for index in 0..<count {
            // Add image
            guard let frame = CGImageSourceCreateImageAtIndex(source, index, nil) else  {
                return nil
            }
            
            // At it's delay in cs
            let frameDuration = UIImage.delayForImageAtIndex(Int(index),source: source) ?? 0.1
            
            frames.append(frame)
            frameDurations.append(Int(frameDuration * 1000.0)) // Seconds to ms
        }
        
        // Calculate full duration
        let duration = frameDurations.reduce(0, +)
        
        // Get frames
        let gcd = gcdForArray(frameDurations)
        var images = [UIImage]()
        
        for index in 0..<count {
            let image = UIImage(cgImage: frames[Int(index)])
            let frameCount = Int(frameDurations[Int(index)] / gcd)
            
            for _ in 0..<frameCount {
                images.append(image)
            }
        }
        
        // Heyhey
        let animation = UIImage.animatedImage(with: images,
                                              duration: Double(duration) / 1000.0)
        
        return animation
    }
    
}
