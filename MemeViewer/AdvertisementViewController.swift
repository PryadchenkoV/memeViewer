//
//  AdvertisementViewController.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 28/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import WebKit

class AdvertisementViewController: UIViewController {

    var url: URL?
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = url else {
            print("[AdvertisementViewController] url is nil. Return")
            return
        }
        self.webView.load(URLRequest(url: url))
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
