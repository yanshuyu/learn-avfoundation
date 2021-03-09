//
//  MSVideoFramsThumbnailView.swift
//  08_MediaSamplerVisualizer
//
//  Created by sy on 2020/3/25.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit

class MSVideoFramsThumbnailView: UIView, AssetLoadable {
    
    public private(set) var contentView: UIView!
    public var contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    private var glView: GLKView?

    //
    // MARK: - init
    //
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.clipsToBounds = true
        self.contentView = UIView()
        self.contentView.clipsToBounds = true
        self.contentView.backgroundColor = nil
        self.addSubview(self.contentView)
        self.sendSubviewToBack(self.contentView)
        layoutContentView()
    }
    
    //
    // MARK: - asset loading
    //
    private class GenerateThumbnailsOperation: Operation, Cancelable {
        var asset: AVAsset?
        var times: [CMTime]?
        var thumbnailSize: CGSize?
        var finishBlock: ((AssetLoadStatus, Error?, [UIImage]?)->Void)?
        var failTorelenceRate: CGFloat = 0.1
        
        override func main() {
            guard !self.isCancelled,
                let videoAsset = self.asset,
                let timePoints = self.times else {
                    return
            }
            
            let imageGenerator = AVAssetImageGenerator(asset: videoAsset)
            imageGenerator.maximumSize = self.thumbnailSize ?? CGSize.zero
            
            var failedCnt = 0
            var thumbnails = [UIImage](repeating: UIImage(), count: timePoints.count)
            for idx in 0..<timePoints.count {
                guard !self.isCancelled else {
                    return
                }
                
                var image: CGImage?
                do {
                    image = try imageGenerator.copyCGImage(at: timePoints[idx], actualTime: nil)
                    thumbnails[idx] = image != nil ? UIImage(cgImage: image!) : UIImage()
                } catch {
                    failedCnt += 1
                    let failRate = CGFloat(failedCnt) / CGFloat(timePoints.count)
                    if failRate >= self.failTorelenceRate {
                        finishBlock?(AssetLoadStatus.failed, error, nil)
                        return
                    }
                    thumbnails[idx] = image != nil ? UIImage(cgImage: image!) : UIImage()
                }
            }
            
            guard !self.isCancelled else {
                return
            }
            
            finishBlock?(AssetLoadStatus.completed, nil, thumbnails)
        }
        
        
        override func cancel() {
            guard !self.isCancelled, !self.isFinished else {
                return
            }
            finishBlock?(AssetLoadStatus.cancelled, nil, nil)
            super.cancel()
        }
        
    }
    
    private var asset: AVAsset?
    private var lastLoadQueue: OperationQueue?
    private var lastCanceller: Cancelable?
    
    private(set) var thumbnails: [UIImage]?
    
    @discardableResult
    func load(_ asset: AVAsset, queue: OperationQueue?, completionHandler: AssetLoadCompletionHandler?) -> Cancelable? {
        self.lastCanceller?.cancel()
        self.asset = asset
        self.lastLoadQueue = queue
        
        let loadOp = GenerateThumbnailsOperation()
        loadOp.asset = asset
        loadOp.qualityOfService = .userInitiated
        loadOp.finishBlock = { [weak self] (status, error, thumbnails) in
            guard let strongSelf = self else { return }
            if status == .completed {
                strongSelf.thumbnails = thumbnails
                DispatchQueue.main.async {
                    strongSelf.setNeedsDisplay()
                    completionHandler?(.completed, nil)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler?(status, error)
            }
        }
        
        let q = queue ?? OperationQueue.main
        q.addOperation(loadOp)
        
        self.lastCanceller = loadOp
        
        return loadOp
    }
    
    //
    // MARK: - layout
    //
    private var contentViewConstraints: [NSLayoutConstraint]?
    private func layoutContentView() {
        if self.contentViewConstraints == nil {
            self.contentView.translatesAutoresizingMaskIntoConstraints = false
            self.contentViewConstraints = [
                self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self.contentInset.left),
                self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -self.contentInset.bottom),
                self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -self.contentInset.right),
                self.contentView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.contentInset.top),
            ]
            self.contentViewConstraints?.forEach {
                $0.isActive = true
            }
            return
        }
        
        guard let constraints = self.contentViewConstraints else {
            return
        }
        
        UIView.animate(withDuration: 0.5) {
            constraints[0].constant = self.contentInset.left
            constraints[1].constant = -self.contentInset.bottom
            constraints[2].constant = -self.contentInset.right
            constraints[3].constant = self.contentInset.top
        }
        
    }
    
}
