//
//  ViewController.swift
//  07_BarcodeScanner
//
//  Created by sy on 2020/3/13.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {
    private var scanController = BarcodeScanController()
    private var sessionIsSetUp = false
    var scanner: CodeScanner! {
        didSet {
            self.title = self.scanner.name
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scanController.delegate = self
        self.view.addSubview(self.scanController.previewView)
        self.view.sendSubviewToBack(self.scanController.previewView)
        self.scanController.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.scanController.previewView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.scanController.previewView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.navigationController?.navigationBar.bounds.height ?? 0).isActive = true
        self.scanController.previewView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.scanController.previewView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        
        let prepareBlock = { [weak self] in
            DispatchQueue.main.async {
                if let strongSelf = self {
                    strongSelf.sessionIsSetUp = strongSelf.scanController.setUpScanSession(for: strongSelf.scanner.codeTypes, interestAera: nil)
                    if !strongSelf.sessionIsSetUp {
                        let alert = UIAlertController(title: "Error",
                                                      message: "set up scan session failed.",
                                                      preferredStyle: .alert)
                        strongSelf.present(alert, animated: true, completion: nil)
                    } else {
                        strongSelf.scanController.startScan()
                    }
                }
            }
        }
        
        if self.scanController.authorizationStatus() != .authorized {
            self.scanController.requesAuthorization { (allowed) in
                if allowed {
                    prepareBlock()
                }
            }
        } else {
            prepareBlock()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.sessionIsSetUp && !self.scanController.isRuning {
            self.scanController.startScan()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.sessionIsSetUp && self.scanController.isRuning {
            self.scanController.stopScan()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "barCodePresentVC",
            let dstVC = segue.destination as? BarcodePresentingViewController,
            let image = sender as? UIImage {
            dstVC.barCodeImage = image
            dstVC.title = "scaned code"
            dstVC.doneBlock = { [weak self] in
                if let strongSelf = self,
                !strongSelf.scanController.isRuning {
                    strongSelf.scanController.startScan()
                }
            }
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        
    }
    
}


extension ScanViewController: BarcodeScanControllerDelegate {
    func barcodeScanController(_ controller: BarcodeScanController, failedToConfigureSessionWith error: BarcodeScanController.SessionConfigurationError) {
        print("scan session config error: \(error)")
    }
    
    func barcodeScanController(_ controller: BarcodeScanController, didOutput codeString: String?, bounds: CGRect, corners: [CGPoint]) {
        print("output code: \(codeString ?? "nil"), bounds: \(bounds), corners: \(corners)")
        if let codeString = codeString {
            if self.scanner.codeTypes.contains(.qr) {
                if let image = UIImage.generateQRCode(codeString: codeString, width: 300) {
                    self.scanController.stopScan()
                    performSegue(withIdentifier: "barCodePresentVC", sender: image)
                    return
                }
            }
            
            if self.scanner.codeTypes.contains(.code128) {
                if let image = UIImage.generateCode128(codeString: codeString, size: CGSize(width: 300, height: 100)) {
                    self.scanController.stopScan()
                    performSegue(withIdentifier: "barCodePresentVC", sender: image)
                    return
                }
            }
        }
    }
    
    func barcodeScanControllerSessionBeginInterrupted(_ controller: BarcodeScanController) {
        print("scan session is interrupted")
    }
    
    func barcodeScanControllerSessionEndInterrupted(_ controller: BarcodeScanController) {
        print("scan session end interrupted")
    }
    
    
}

