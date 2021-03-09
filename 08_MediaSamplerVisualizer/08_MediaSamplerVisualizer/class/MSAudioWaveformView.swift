//
//  MSAudioWaveformView.swift
//  08_MediaSamplerVisualizer
//
//  Created by sy on 2020/3/24.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit
import AVFoundation


class MSAudioWaveformView: UIView, AssetLoadable {
    private var contentView: UIView!
    public var contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4) {
        didSet {
            if self.contentInset != oldValue {
                layoutContentView()
                reloadWaveformIfNeeded()
            }
        }
    }
    private var contentViewConstraints: [NSLayoutConstraint]?
    
    private var lastLoadCanceller: Cancelable?
    private var lastLoadQueue: OperationQueue?
    
    public var waveBounds: CGRect {
        return self.contentView.bounds
    }
    private var waveSampleCount: Int {
        return Int(self.waveBounds.width * self.actualWaveScale)
    }
    private var actualWaveScale: CGFloat = 1 {
        didSet {
            if self.actualWaveScale != oldValue {
                reloadWaveformIfNeeded()
            }
        }
    }
    public var waveScale: CGFloat {
        get {
            return self.actualWaveScale
        }
        set {
            var scale = min(newValue, 1)
            scale = max(scale, 0)
            self.actualWaveScale = scale
        }
    }

    
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
        self.contentView = UIView()
        self.contentView.backgroundColor = nil
        self.contentView.clipsToBounds = true
        addSubview(self.contentView)
        self.sendSubviewToBack(self.contentView)
        self.clipsToBounds = true
        layoutContentView()

    }
    
    //
    // MARK: - layout
    //
    override func layoutSubviews() {
        super.layoutSubviews()
        reloadWaveformIfNeeded()
    }
    
    private func reloadWaveformIfNeeded() {
        if let audio = self.asset {
            self.lastLoadCanceller?.cancel()
            self.lastLoadCanceller = load(audio,
                                          queue: self.lastLoadQueue,
                                          completionHandler: nil)
        }
    }
    
    //
    // MARK: - rendering
    //
    public enum WaveStyle: Int {
        case average = 0
        case maximumal = 1
        case minimumal = 2
    }
    
    private class WaveNodeView: UIView {
        override class var layerClass: AnyClass {
            return CAShapeLayer.self
        }
        public var nodeLayer: CAShapeLayer {
            return self.layer as! CAShapeLayer
        }
    }

    public var wavestyle: WaveStyle = .average {
        didSet {
            if self.wavestyle != oldValue {
                reloadWaveformIfNeeded()
            }
        }
    }
    public var waveColor: UIColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
    public var borderColor: UIColor? {
        get {
            if let color = self.layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    public var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    public var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
    
    private var waveNodes: [WaveNodeView]?
    
    override func draw(_ rect: CGRect) {
        self.waveNodes?.forEach {$0.removeFromSuperview()}
        self.waveNodes = nil
        if rect.width > 0 && rect.height > 0,
            let samples = self.samples,
            samples.count > 0,
            self.waveScale > 0 {
            
            let w = self.waveBounds.width / CGFloat(samples.count)
            let h = self.waveBounds.height
            let x = sqrt(self.waveScale)
            let y = sqrt(x)
            let lineWidth = w * y
            var nodes = Array<WaveNodeView>()
            samples.enumerated().forEach { (idx, sample) in
                let nodeView = WaveNodeView(frame: CGRect(x: CGFloat(idx) * w, y: 0, width: w, height: h))
                self.contentView.addSubview(nodeView)
                let wavePath = UIBezierPath()
                let upperPoint = CGPoint(x: 0.5 * w, y: 0.5 * h * (1 - sample))
                let lowerPoint = CGPoint(x: 0.5 * w, y:0.5 * h * (1 + sample))
                wavePath.move(to: upperPoint)
                wavePath.addLine(to: lowerPoint)
                nodeView.nodeLayer.strokeColor = self.waveColor.cgColor
                nodeView.nodeLayer.lineCap = .round
                nodeView.nodeLayer.lineJoin = .round
                nodeView.nodeLayer.lineWidth = lineWidth
                nodeView.nodeLayer.path = wavePath.cgPath
                nodes.append(nodeView)
            }
            self.waveNodes = nodes
        }
    }
    
    //
    // MARK: - Asset loading
    //
    private class LoadOperation: Operation, Cancelable{
          var reader: AVAssetReader?
          var output: AVAssetReaderTrackOutput?
          var expectedSampleCount: Int?
          var waveStyle: WaveStyle?
          var finishBlock: ((AVAssetReader.Status, [CGFloat]?)->Void)?
          
          override func main() {
              guard !self.isCancelled,
                  let audioReader = self.reader,
                  let audioOutput = self.output else {
                      return
              }
              
              // read sample
              audioReader.startReading()
              
              var data = Data()
              var dataPtr: UnsafeMutablePointer<Int8>?
              while audioReader.status == .reading {
                  guard !self.isCancelled else {
                      break
                  }
                  if let sampleBuffer = audioOutput.copyNextSampleBuffer(),
                      let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                      var dataLen = 0
                      CMBlockBufferGetDataPointer(dataBuffer,
                                                  atOffset: 0,
                                                  lengthAtOffsetOut: nil,
                                                  totalLengthOut: &dataLen,
                                                  dataPointerOut: &dataPtr)
                      if let unwrapDataPtr = dataPtr, dataLen > 0 {
                          data.append(UnsafeBufferPointer(start: unwrapDataPtr, count: dataLen))
                      }
                      
                      CMSampleBufferInvalidate(sampleBuffer)
                  }
              }
              
              if self.isCancelled {
                  return
              }
              
              // down sample
              switch audioReader.status {
                  case .completed:
                      let samples = downSample(for: data)
                      if !self.isCancelled {
                          self.finishBlock?(AVAssetReader.Status.completed, samples)
                      }
                      break
                  default:
                      self.finishBlock?(audioReader.status, nil)
                      break
              }
          }
          
          override func cancel() {
              guard !self.isFinished && !self.isCancelled else {
                  return
              }
              
              self.reader?.cancelReading()
              self.finishBlock?(AVAssetReader.Status.cancelled, nil)
              super.cancel()
          }
          
          private func downSample(for data: Data) -> [CGFloat] {
              guard !self.isCancelled else {
                  return []
              }
              
              let sampleSize =  MemoryLayout<Int16>.stride
              let totalCount = data.count / sampleSize
              var expetedCount = self.expectedSampleCount ?? totalCount
              expetedCount = expetedCount > totalCount ? totalCount : expetedCount
              
              if expetedCount <= 0 {
                  return []
              }
              
              let binSampleCount = totalCount / expetedCount
              let binByteCount = binSampleCount * sampleSize
              var samples = Array<CGFloat>(repeating: 0, count: expetedCount)
              
              var i = 0
              let binBufferPtr = UnsafeMutableBufferPointer<Int16>.allocate(capacity: binSampleCount)
              defer {
                  binBufferPtr.deallocate()
              }
              while i < expetedCount {
                  if self.isCancelled {
                      return []
                  }
                  
                  let startIndex = i * binByteCount
                  let endIndex = startIndex + binByteCount
                  if endIndex > data.count {
                      break
                  }
                  
                  data.copyBytes(to: binBufferPtr, from: startIndex..<endIndex)
                  samples[i] = processSampleBuffer(binBufferPtr)
                  i += 1
              }
              
              guard let maxSample = samples.max() else {
                  return []
              }

              samples = samples.map { $0 / maxSample }
              
              guard !self.isCancelled else {
                  return []
              }
              
              return samples
          }
          
          private func processSampleBuffer(_ bufferPtr: UnsafeMutableBufferPointer<Int16>) -> CGFloat {
              let style = self.waveStyle ?? WaveStyle.average
              switch style {
                  case .average:
                      var sum: CGFloat = 0
                      var cnt: CGFloat = 0
                      bufferPtr.forEach { (sample) in
                          sum += CGFloat(Int16(bigEndian: sample))
                          cnt += 1
                      }
                      return abs(sum / cnt)
      
                  case .maximumal:
                      var max: CGFloat = 0
                      bufferPtr.forEach { (sample) in
                          let floatSample = CGFloat(Int16(bigEndian: sample))
                          max = floatSample > max ? floatSample : max
                      }
                      return abs(max)
                  
                  case .minimumal:
                      var min: CGFloat?
                      bufferPtr.forEach { (sample) in
                          let floatSample = CGFloat(Int16(bigEndian: sample))
                          min = min ?? floatSample
                          min = floatSample < min! ? floatSample : min
                      }
                      return abs(min!)
              }
          }
      }
    private var asset: AVAsset?
    private(set) var samples: [CGFloat]?
    
    @discardableResult
    func load(_ asset: AVAsset, queue: OperationQueue?, completionHandler: AssetLoadCompletionHandler?) -> Cancelable? {
        self.lastLoadCanceller?.cancel()
        self.asset = asset
        self.lastLoadQueue = queue
        // read audio samples with avasset reader
        var audioReader: AVAssetReader!
        do {
            audioReader = try AVAssetReader(asset: asset)
        } catch  {
            DispatchQueue.main.async {
                completionHandler?(.failed, error)
            }
            return nil
        }
        
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            let formatSettings: [String:Any] = [
                AVFormatIDKey:kAudioFormatLinearPCM,
                AVLinearPCMBitDepthKey:16,
                AVLinearPCMIsFloatKey:false,
                AVLinearPCMIsBigEndianKey:true,
            ]
            let audioTrackOutput = AVAssetReaderTrackOutput(track: audioTrack,
                                                            outputSettings: formatSettings)
            
            guard audioReader.canAdd(audioTrackOutput) else {
                DispatchQueue.main.async {
                    completionHandler?(.failed,nil)
                }
                return nil
            }
            audioReader.add(audioTrackOutput)
            
            let loadOp = LoadOperation()
            loadOp.reader = audioReader
            loadOp.output = audioTrackOutput
            loadOp.expectedSampleCount = self.waveSampleCount
            loadOp.waveStyle = self.wavestyle
            loadOp.qualityOfService = .userInitiated
            loadOp.finishBlock = { [weak self] (readerStatus, samples) in
                switch readerStatus {
                    case .completed: // drawing samples
                        if let strongSelf = self {
                            strongSelf.samples = samples
                            DispatchQueue.main.async {
                                strongSelf.setNeedsDisplay()
                                completionHandler?(.completed, nil)
                            }
                        }
                        break
                    default:
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }
                            completionHandler?(strongSelf.assetReaderStatusToAssetLoadStatus(readerStatus),nil)
                        }
                        break
                }
            }
            
            let q = queue ?? OperationQueue.main
            q.addOperation(loadOp)
            self.lastLoadCanceller = loadOp
            
            return loadOp
        }
        
        DispatchQueue.main.async {
            completionHandler?(.failed,nil)
        }
        return nil
        
    }
    
    //
    // MARK: - private helpper
    //
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

    private func assetReaderStatusToAssetLoadStatus(_ readerStatus: AVAssetReader.Status) -> AssetLoadStatus {
        var loadStatus: AssetLoadStatus = .unkown
        switch readerStatus {
            case .completed:
                loadStatus = .completed
                break
            case .reading:
                loadStatus = .loading
                break
            case .cancelled:
                loadStatus = .cancelled
                break
            case .failed:
                loadStatus = .failed
                break
            default:
                loadStatus = .unkown
                break
        }
        
        return loadStatus
    }
    
    
}
