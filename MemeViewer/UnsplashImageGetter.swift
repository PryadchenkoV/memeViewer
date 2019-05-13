//
//  UnsplashImageGetter.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 04/05/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit
import CoreData

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
    
    var arrayOfImagesData = [NSManagedObject]()
    
    override init() {
        super.init()
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Image")
        do {
            self.willChangeValue(forKey: "arrayOfImagesData")
            arrayOfImagesData = try managedContext.fetch(fetchRequest)
            self.didChangeValue(forKey: "arrayOfImagesData")
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func prepareFirstArrayOfImages() {
        getNumberOfRandomPhotos(count: 5)
        UserDefaults.standard.setValue(Date(), forKey: "FirstLoadTime")
    }
    
    func loadNewRandomPhoto() {
        getNumberOfRandomPhotos(count: 1)
    }
    
    func getNumberOfRandomPhotos(count: Int) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let entity =
            NSEntityDescription.entity(forEntityName: "Image",
                                       in: managedContext)!
        DispatchQueue.global(qos: .background).async {
            for _ in 0..<count {
                let image = NSManagedObject(entity: entity,
                                            insertInto: managedContext)
                image.setValue(NSUUID().uuidString, forKeyPath: "id")
                DispatchQueue.main.async {
                    self.willChangeValue(forKey: "arrayOfImagesData")
                    do {
                        try managedContext.save()
                        self.arrayOfImagesData.append(image)
                    } catch let error as NSError {
                        print("Could not save. \(error), \(error.userInfo)")
                    }
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
                                if let index = self.arrayOfImagesData.firstIndex(where: { $0.value(forKey: "author") == nil
                                }) {
                                    self.arrayOfImagesData[index].setValue(imageData.description, forKey: "descr")
                                    self.arrayOfImagesData[index].setValue(imageData.user.name, forKey: "author")
                                    do {
                                        try managedContext.save()
                                    } catch let error as NSError {
                                        print("Could not save. \(error), \(error.userInfo)")
                                    }
                                    if let urlForSmallImage = URL(string: imageData.urls.small) {
                                        let urlRequestForSmallImage = URLRequest(url: urlForSmallImage)
                                        URLSession.shared.dataTask(with: urlRequestForSmallImage, completionHandler: { (data, _, error) in
                                            if let data = data {
                                                DispatchQueue.main.async {
                                                    self.arrayOfImagesData[index].setValue(data, forKey: "smallImage")
                                                    do {
                                                        try managedContext.save()
                                                    } catch let error as NSError {
                                                        print("Could not save. \(error), \(error.userInfo)")
                                                    }
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kSmallImageDownloadedNotificationName), object: nil, userInfo: ["id":self.arrayOfImagesData[index].value(forKey: "id")])
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
                                                    self.arrayOfImagesData[index].setValue(data, forKey: "mainImage")
                                                    do {
                                                        try managedContext.save()
                                                    } catch let error as NSError {
                                                        print("Could not save. \(error), \(error.userInfo)")
                                                    }
                                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: kRegularImageDownloadedNotificationName), object: nil, userInfo: ["id":self.arrayOfImagesData[index].value(forKey: "id")])
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
