//
//  ViewController.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 28/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UILabel!
    @IBOutlet weak var authorTextField: UILabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var commentView: UIVisualEffectView!
    @IBOutlet weak var separator: UIView!
    
    var id: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.progressIndicator.startAnimating()
            if let id = self.id, let imageData = UnsplashImageGetter.shared.arrayOfImagesData.first(where: { $0.id == id }) {
                self.setImageData(with: imageData)
            }
        }
        
        let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(tapOnDetailsView(sender:)))
        commentView.addGestureRecognizer(tapGuesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(imageDownloaded(notification:)), name: NSNotification.Name(rawValue: kSmallImageDownloadedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageDownloaded(notification:)), name: NSNotification.Name(rawValue: kRegularImageDownloadedNotificationName), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func imageDownloaded(notification: Notification) {
        if let userInfo = notification.userInfo as? [String: String], let notificationId = userInfo["id"], let id = id, id == notificationId {
            if let imageData = UnsplashImageGetter.shared.arrayOfImagesData.first(where: { $0.id == notificationId
            }) {
                setImageData(with: imageData)
            }
        }
    }
    
    @objc func tapOnDetailsView(sender: Any) {
        guard let attributedTextWidth = self.descriptionTextField.attributedText?.size().width else {
            return
        }
        var numberOfStrings = attributedTextWidth / commentView.bounds.size.width
        if numberOfStrings - CGFloat(Int(numberOfStrings)) != 0 {
            numberOfStrings += 1
        }
        if self.descriptionTextField.numberOfLines == 1 {
            if numberOfStrings > 1 {
                 self.descriptionTextField.numberOfLines = Int(numberOfStrings)
            }
        } else {
            self.descriptionTextField.numberOfLines = 1
        }
    }
    
    func setImageData(with imageData: UnsplashImageGetter.Image) {
        DispatchQueue.main.async {
            if let author = imageData.author {
                self.authorTextField.isHidden = false
                self.authorTextField.text = author
            } else {
                self.authorTextField.isHidden = true
            }
            if let description = imageData.description {
                self.descriptionTextField.isHidden = false
                self.separator.isHidden = false
                self.descriptionTextField.text = description
            } else {
                self.separator.isHidden = true
                self.descriptionTextField.isHidden = true
            }
            if let mainImage = imageData.mainImage {
                self.imageView.image = mainImage
                self.progressIndicator.stopAnimating()
                
            } else if let smallImage = imageData.smallImage {
                
                self.imageView.image = smallImage
                self.progressIndicator.stopAnimating()
            }
        }
    }
    
    
}

