//
//  BarcodePresentingViewController.swift
//  07_BarcodeScanner
//
//  Created by sy on 2020/3/14.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

class BarcodePresentingViewController: UIViewController {
    @IBOutlet weak var titleItem: UINavigationItem!
    var barCodeImage = UIImage()
    var doneBlock: (()->Void)?
    
    @IBOutlet weak var barCodeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.barCodeImageView.image = barCodeImage
        self.titleItem.title = self.title
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.doneBlock?()
    }
    

    @IBAction func onDonePressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
