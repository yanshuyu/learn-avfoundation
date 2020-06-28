//
//  CiImage+extension.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/28.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import CoreImage


extension CIImage {
    func setOpacity(_ alpha: CGFloat) -> CIImage {
        let filter = CIFilter(name: "CIColorMatrix")
        filter?.setDefaults()
        filter?.setValue(self, forKey: kCIInputImageKey)
        let alphaVector = CIVector.init(x: 0, y: 0, z: 0, w: alpha)
        filter?.setValue(alphaVector, forKey: "inputAVector")
        if let outputImage = filter?.outputImage {
            return outputImage
        }
        return self
    }
}
