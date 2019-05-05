//
//  UnsplashImageGetter.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 04/05/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit

let kAccessKeyForUnsplashAPI = "d3e87795d458e1b1a5d5251f8dc9f05d7e718c9a8c48eb5f3e04cfb94a634d17"
let kSmallImageDownloadedNotificationName = "com.pryadchenko.memeViewer.smallImageDownloaded"
let kRegularImageDownloadedNotificationName = "com.pryadchenko.memeViewer.regularImageDownloaded"

extension URL {
    private static var unsplashURL: String {
        return "https://api.unsplash.com/"
    }
    
    static func unsplashURL(with string: String) -> URL? {
        return URL(string: unsplashURL + string)
    }
}

class UnsplashImageGetter: NSObject {
    
    static let shared = UnsplashImageGetter()
    
    struct Image {
        var id: String?
        var mainImage: UIImage?
        var smallImage: UIImage?
        var description: String?
        var author: String?
        
        init(id: String? = nil, mainImage: UIImage? = nil, smallImage: UIImage? = nil, description: String? = nil, author: String? = nil) {
            self.id = id
            self.mainImage = mainImage
            self.smallImage = smallImage
            self.description = description
            self.author = author
        }
        
    }
    
    struct URLs: Decodable {
        let raw: String
        let full: String
        let regular: String
        let small: String
        let thumb: String
    }
    
    struct User: Decodable {
        let name: String
    }
    
    struct UnsplashImageData: Decodable {
        let id: String
        let width: Int
        let height: Int
        let color: String
        let description: String?
        let urls: URLs
        let user: User
    }
    
    var arrayOfImagesData = [Image]()
    
    func prepareFirstArrayOfImages() {
        getNumberOfRandomPhotos(count: 5)
    }
    
    func loadNewRandomPhoto() {
        getNumberOfRandomPhotos(count: 1)
    }
    
    func getNumberOfRandomPhotos(count: Int) {
        DispatchQueue.global(qos: .background).async {
            for _ in 0..<count {
                var image = Image()
                image.id = NSUUID().uuidString
                DispatchQueue.main.async {
                    self.willChangeValue(forKey: "arrayOfImagesData")
                    self.arrayOfImagesData.append(image)
                    self.didChangeValue(forKey: "arrayOfImagesData")
                }
            }
            if let url = URL.unsplashURL(with: "photos/random?count=\(count)") {
                var request = URLRequest(url: url)
                request.setValue("Client-ID \(kAccessKeyForUnsplashAPI)", forHTTPHeaderField: "Authorization")
                URLSession.shared.dataTask(with: request) { (data, _, error) in
                    if let data = data {
                        do {
                            let imagesData = try JSONDecoder().decode([UnsplashImageData].self, from: data)
                            //                            image.id = imageData.id
                            for imageData in imagesData {
                                if let index = self.arrayOfImagesData.firstIndex(where: { $0.author == nil
                                }) {
                                    self.arrayOfImagesData[index].description = imageData.description
                                    self.arrayOfImagesData[index].author = imageData.user.name
                                    if let urlForSmallImage = URL(string: imageData.urls.small) {
                                        let urlRequestForSmallImage = URLRequest(url: urlForSmallImage)
                                        URLSession.shared.dataTask(with: urlRequestForSmallImage, completionHandler: { (data, _, error) in
                                            if let data = data {
                                                DispatchQueue.main.async {
                                                    let tmpImage = UIImage(data: data)
                                                    self.arrayOfImagesData[index].smallImage = UIImage(data: data)
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kSmallImageDownloadedNotificationName), object: nil, userInfo: ["id":self.arrayOfImagesData[index].id])
                                                }
                                            } else if let error = error {
                                                print("[UnsplashImageGetter] Error while downloading Small Image: " + error.localizedDescription)
                                            }
                                        }).resume()
                                    }
                                    if let urlForMainImage = URL(string: imageData.urls.regular) {
                                        let urlRequestForMainImage = URLRequest(url: urlForMainImage)
                                        URLSession.shared.dataTask(with: urlRequestForMainImage, completionHandler: { (data, _, error) in
                                            if let data = data {
                                                DispatchQueue.main.async {
                                                    let tmpImage = UIImage(data: data)
                                                    self.arrayOfImagesData[index].mainImage = UIImage(data: data)
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kRegularImageDownloadedNotificationName), object: nil, userInfo: ["id":self.arrayOfImagesData[index].id])
                                                }
                                            } else if let error = error {
                                                print("[UnsplashImageGetter] Error while downloading Main Image: " + error.localizedDescription)
                                            }
                                        }).resume()
                                    }
                                }
                            }
                        }
                        catch let error {
                            print("[UnsplashImageGetter] Error while decoding json data: " + error.localizedDescription)
                        }
                    }
                    }.resume()
                
            }
        }
    }
}
