//
//  VEVideoCompositor.swift
//  05_videoEditor
//
//  Created by sy on 2020/6/22.
//  Copyright © 2020 sy. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import GLKit


enum CompositionError: Error {
    case invailedCompositionInstruction
    case failedToGetSourceFrame
    case missingMainTrackLayer
    case invailedNumberOfMainTrackLayer
    case missingRenderContext
    case failedToCreateOutputBuffer
    case unKnowedError
}

class VEVideoCompositor:NSObject, AVVideoCompositing {
    fileprivate lazy var syncQueue: DispatchQueue = {
        return DispatchQueue(label: "com.videoEditor.sy.syncQueue",
                             qos: .userInitiated,
                             attributes: [.concurrent],
                             autoreleaseFrequency: .inherit,
                             target: nil)
    }()
    
    fileprivate lazy var compositionQueue: DispatchQueue = {
        return DispatchQueue(label: "com.videoEditor.sy.videoComposition",
                             qos: .userInitiated,
                             attributes: [],
                             autoreleaseFrequency: .workItem,
                             target: nil)
    }()
    
    fileprivate var renderContext: AVVideoCompositionRenderContext?
    
    // multiple reader, one writer at time
    fileprivate var _shouldCancelAllCompositionRequest: Bool = false
    fileprivate var shouldCancelAllCompositionRequest: Bool {
        get {
            var currentValue = false
            self.syncQueue.sync {
                currentValue  = self._shouldCancelAllCompositionRequest
            }
            return currentValue
        }
        set {
            self.syncQueue.async(group: nil,
                                 qos: .unspecified,
                                 flags: [.barrier]) {
                                    self._shouldCancelAllCompositionRequest = newValue
            }
        }
    }
    
    fileprivate lazy var ciContext: CIContext = {
//        if let glContext = EAGLContext(api: .openGLES3) {
//            return CIContext(eaglContext: glContext)
//        }
        return CIContext()
    }()
    
    var sourcePixelBufferAttributes: [String : Any]? {
        return [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any] {
        return [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
        String(kCVPixelBufferOpenGLESCompatibilityKey): true]
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        self.renderContext = newRenderContext
        self.shouldCancelAllCompositionRequest = true
        self.compositionQueue.async {
            self.shouldCancelAllCompositionRequest = false
        }
    }
    
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        self.compositionQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            if strongSelf.shouldCancelAllCompositionRequest {
                asyncVideoCompositionRequest.finishCancelledRequest()
                return
            }

            do {
                if let composedFrame = try strongSelf.renderCompositionForRequest(asyncVideoCompositionRequest) {
                    asyncVideoCompositionRequest.finish(withComposedVideoFrame: composedFrame)
                } else {
                    asyncVideoCompositionRequest.finish(with: CompositionError.unKnowedError)
                }
            } catch {
                asyncVideoCompositionRequest.finishCancelledRequest()
                print("asyncVideoCompositionRequest failed with error: \(error)")
            }
        }

    }
    
    
    fileprivate func renderCompositionForRequest(_ request: AVAsynchronousVideoCompositionRequest) throws -> CVPixelBuffer? {
        guard let compInst = request.videoCompositionInstruction as? VEVideoCompositionInstruction else {
            throw CompositionError.invailedCompositionInstruction
        }
        
        guard let renderContext = self.renderContext else {
            throw CompositionError.missingRenderContext
        }
        
        guard let composedImage = try compInst.renderCompostion(for: request) else {
            return nil
        }
        
        guard let outputBuffer = renderContext.newPixelBuffer() else {
            throw CompositionError.failedToCreateOutputBuffer
        }
        
        self.ciContext.render(composedImage, to: outputBuffer)
        
        return outputBuffer
    }
    
    
}
