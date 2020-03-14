//
//  PickScanneTableViewController.swift
//  07_BarcodeScanner
//
//  Created by sy on 2020/3/14.
//  Copyright © 2020 sy. All rights reserved.
//

import UIKit

struct CodeScanner {
    var name: String
    var codeTypes: [BarcodeScanController.CodeType]
}

class PickScanneTableViewController: UITableViewController {
    var allCodeSanners: [CodeScanner] = [
        CodeScanner(name: "QR", codeTypes: [.qr]),
        CodeScanner(name: "Aztec", codeTypes: [.aztec]),
        CodeScanner(name: "Code128", codeTypes: [.code128])
    ]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Code Scanners"
    }
    
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allCodeSanners.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)
        cell.textLabel?.text = allCodeSanners[indexPath.row].name
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scannerVC",
            let indexPath = self.tableView.indexPathForSelectedRow,
            let scannerVC = segue.destination as? ScanViewController {
            scannerVC.scanner = self.allCodeSanners[indexPath.row]
            self.tableView.deselectRow(at: indexPath, animated: false)
        }
    }

}
