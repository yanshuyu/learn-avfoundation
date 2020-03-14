//
//  BarcodeScannerPreviewView.swift
//  07_BarcodeScanner
//
//  Created by sy on 2020/3/13.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation

class BarcodeScannerPreviewView: UIView {

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return self.layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return self.previewLayer.session
        }
        
        set {
            self.previewLayer.session = newValue
        }
    }
    

}
