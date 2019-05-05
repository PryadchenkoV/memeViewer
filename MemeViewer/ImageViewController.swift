//
//  ViewController.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 28/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

extension UILabel {
    func calculateMaxLines() -> Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(Float.infinity))
        let charSize = font.lineHeight
        let text = (self.text ?? "") as NSString
        let textSize = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        let linesNumber = Int(ceil(textSize.height/charSize))
        return linesNumber
    }
}

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextField: UILabel!
    @IBOutlet weak var authorTextField: UILabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet weak var commentView: UIVisualEffectView!
    @IBOutlet weak var separator: UIView!
    @IBOutlet weak var commentScrollView: UIScrollView!
    @IBOutlet weak var commentScrollViewHeigth: NSLayoutConstraint!
    
    var id: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.progressIndicator.startAnimating()
            if let id = self.id, let imageData = UnsplashImageGetter.shared.arrayOfImagesData.first(where: { $0.value(forKey: "id") as! String == id }) {
                self.setImageData(with: imageData)
            }
        }
        
        let tapGuesture = UITapGestureRecognizer(target: self, action: #selector(tapOnDetailsView(sender:)))
        commentView.addGestureRecognizer(tapGuesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(imageDownloaded(notification:)), name: NSNotification.Name(rawValue: kSmallImageDownloadedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageDownloaded(notification:)), name: NSNotification.Name(rawValue: kRegularImageDownloadedNotificationName), object: nil)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 10.0
        
        let doubleTapGuest = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView(recognizer:)))
        doubleTapGuest.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGuest)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.zoomScale = 1.0
    }
    
    @objc func imageDownloaded(notification: Notification) {
        if let userInfo = notification.userInfo as? [String: String], let notificationId = userInfo["id"], let id = id, id == notificationId {
            if let imageData = UnsplashImageGetter.shared.arrayOfImagesData.first(where: { $0.value(forKey: "id") as! String == notificationId
            }) {
                setImageData(with: imageData)
            }
        }
    }
    
    @objc func tapOnDetailsView(sender: Any) {
        if !self.commentScrollView.isHidden {
            if self.descriptionTextField.numberOfLines == 1 {
                self.descriptionTextField.numberOfLines = 0
                let viewHeight = Int(descriptionTextField.calculateMaxLines()) * 24
                if viewHeight > Int(UIScreen.main.bounds.height/2) {
                    self.commentScrollViewHeigth.constant = UIScreen.main.bounds.height/2
                } else {
                    self.commentScrollViewHeigth.constant = CGFloat(viewHeight)
                }
            } else {
                self.descriptionTextField.numberOfLines = 1
                self.commentScrollViewHeigth.constant = 24
            }
        }
    }
    
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: 3.0, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func setImageData(with imageData: NSManagedObject) {
        DispatchQueue.main.async {
            if let author = imageData.value(forKey: "author") as? String {
                self.authorTextField.isHidden = false
                self.authorTextField.text = author
            } else {
                self.authorTextField.isHidden = true
            }
            if let description = imageData.value(forKey: "descr") as? String {
                self.descriptionTextField.isHidden = false
                self.commentScrollView.isHidden = false
                self.separator.isHidden = false
                self.descriptionTextField.text = description
            } else {
                self.separator.isHidden = true
                self.commentScrollView.isHidden = true
                self.descriptionTextField.isHidden = true
            }
            if let mainImage = imageData.value(forKey: "mainImage") as? Data {
                self.imageView.image = UIImage(data: mainImage)
                self.progressIndicator.stopAnimating()
                
            } else if let smallImage = imageData.value(forKey: "smallImage") as? Data {
                
                self.imageView.image = UIImage(data: smallImage)
                self.progressIndicator.stopAnimating()
            }
        }
    }
    
    
}

