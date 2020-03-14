//
//  BarcodeScanController.swift
//  07_BarcodeScanner
//
//  Created by sy on 2020/3/13.
//  Copyright © 2020 sy. All rights reserved.
//

import AVFoundation

protocol BarcodeScanControllerDelegate: AnyObject {
    func barcodeScanController(_ controller: BarcodeScanController, failedToConfigureSessionWith error: BarcodeScanController.SessionConfigurationError)
    func barcodeScanController(_ controller: BarcodeScanController, didOutput codeString: String?, bounds: CGRect, corners: [CGPoint])
    func barcodeScanControllerSessionBeginInterrupted(_ controller: BarcodeScanController)
    func barcodeScanControllerSessionEndInterrupted(_ controller: BarcodeScanController)
}

class BarcodeScanController: NSObject {
    enum CodeType {
        case qr
        case aztec
        case code128
        
        init(_ objType: AVMetadataObject.ObjectType) {
            switch objType {
                case .qr:
                    self = .qr
                case .aztec:
                    self = .aztec
                case .code128:
                    self = .code128
                default:
                    self = .qr
            }
        }
        
        var metadataObjectType: AVMetadataObject.ObjectType {
            switch self {
                case .qr:
                    return .qr
                case .aztec:
                    return .aztec
                case .code128:
                    return .code128
            }
        }
    }
    
    weak var delegate: BarcodeScanControllerDelegate?
    private var delegateCallBackQueue: DispatchQueue?
    
    init(delegateQueue: DispatchQueue? = nil) {
        super.init()
        self.delegateCallBackQueue = delegateQueue
        self.previewView.previewLayer.videoGravity = .resizeAspectFill
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionBegin(_:)),
                                               name: Notification.Name.AVCaptureSessionWasInterrupted,
                                               object: self.session)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnd(_:)),
                                               name: Notification.Name.AVCaptureSessionInterruptionEnded,
                                               object: self.session)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //
    // MARK: - permission
    //
    func authorizationStatus() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requesAuthorization(_ compeletionHandler: @escaping (Bool)->Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: compeletionHandler)
    }
    
    
    //
    // MARK: - session management
    //
    enum SessionConfigurationError {
        case noAvailableCaptureHardware
        case inVailedDeviceInput(Error?)
        case inCompatibleDeviceInput
        case inCompatitleDataOutput
    }
    
    private var session = AVCaptureSession()
    private var cameraDeviceInput: AVCaptureDeviceInput?
    private var metadataOutput = AVCaptureMetadataOutput()
    private(set) var previewView = BarcodeScannerPreviewView()
    
    public var availableCodeTypes: [CodeType] {
        let codeTypes = self.metadataOutput.availableMetadataObjectTypes.map { return CodeType($0) }
        let codeTpesUniq: Set<CodeType> = Set(codeTypes)
        let finalCodeTypes = Array<CodeType>(codeTpesUniq)
        return finalCodeTypes
    }
    
    public var isRuning: Bool {
        return self.session.isRunning
    }
    
    public var isInterrupted: Bool {
        return self.session.isInterrupted
    }
    
    @discardableResult
    public func setUpScanSession(for codeTypes: [CodeType], interestAera: CGRect?) -> Bool {
        if self.cameraDeviceInput == nil {
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                          mediaType: .video,
                                                                          position: .back)
            
            guard discoverySession.devices.count > 0 else {
                self.delegate?.barcodeScanController(self, failedToConfigureSessionWith: .noAvailableCaptureHardware)
                return false
            }
            
            do {
                try self.cameraDeviceInput = AVCaptureDeviceInput(device: discoverySession.devices.first!)
            } catch {
                self.delegate?.barcodeScanController(self, failedToConfigureSessionWith: .inVailedDeviceInput(error))
                return false
            }
            
            if self.cameraDeviceInput!.device.isAutoFocusRangeRestrictionSupported {
                do {
                    try self.cameraDeviceInput!.device.lockForConfiguration()
                    self.cameraDeviceInput!.device.autoFocusRangeRestriction = .near
                    self.cameraDeviceInput!.device.unlockForConfiguration()
                } catch  { }
            }
            
            if self.session.canAddInput(self.cameraDeviceInput!) {
                self.session.addInput(self.cameraDeviceInput!)
            } else {
                self.delegate?.barcodeScanController(self, failedToConfigureSessionWith: .inCompatibleDeviceInput)
                return false
            }
            
            self.metadataOutput.setMetadataObjectsDelegate(self, queue: self.delegateCallBackQueue ?? DispatchQueue.main)
            if self.session.canAddOutput(self.metadataOutput) {
                self.session.addOutput(self.metadataOutput)
            } else {
                self.delegate?.barcodeScanController(self, failedToConfigureSessionWith: .inCompatitleDataOutput)
                return false
            }
            
            self.previewView.session = self.session
            self.session.sessionPreset = .medium
        }
        
        self.metadataOutput.metadataObjectTypes = codeTypes.map { return $0.metadataObjectType }
        if let userInterestRect = interestAera {
            self.metadataOutput.rectOfInterest = self.previewView.previewLayer.metadataOutputRectConverted(fromLayerRect: userInterestRect)
        }
        
        return true
    }
    
    func startScan() {
        self.session.startRunning()
    }
    
    func stopScan() {
        self.session.stopRunning()
    }

    //
    // MARK: - session interuption
    //
    @objc private func sessionInterruptionBegin(_ notification: Notification) {
        self.delegate?.barcodeScanControllerSessionBeginInterrupted(self)
    }
    
    @objc private func sessionInterruptionEnd(_ notification: Notification) {
        self.delegate?.barcodeScanControllerSessionEndInterrupted(self)
    }
    
}


extension BarcodeScanController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        if metadataObjects.count > 0,
            let convertedObj = self.previewView.previewLayer.transformedMetadataObject(for: metadataObjects.first!),
            let codeObj = convertedObj as? AVMetadataMachineReadableCodeObject {
            self.delegate?.barcodeScanController(self,
                                                 didOutput: codeObj.stringValue,
                                                 bounds: codeObj.bounds,
                                                 corners: codeObj.corners)
        }
    }
    
}
