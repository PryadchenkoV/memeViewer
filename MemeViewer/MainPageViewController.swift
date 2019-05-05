//
//  MainViewController.swift
//  MemeViewer
//
//  Created by Ivan Pryadchenko on 28/04/2019.
//  Copyright © 2019 MIEM. All rights reserved.
//

import UIKit

let arrayOfURLs = [URL(string: "https://memepedia.ru/letyashhij-kot/"), URL(string: "https://memepedia.ru/dejneris-ulybaetsya/"), URL(string: "https://memepedia.ru/celuj-snimaj/"),
    URL(string: "https://memepedia.ru/tolstyj-tor/"),
    URL(string: "https://memepedia.ru/davajte-posle-majskix/"),
    URL(string: "https://memepedia.ru/ricardo-milos/"),
    URL(string: "https://memepedia.ru/zlaya-sova-duolingo/"),
    URL(string: "https://memepedia.ru/vinni-pux-v-smokinge/")
]

class MainPageViewController: UIPageViewController {
    
    var currentIndex = 0
    var arrayOfViewControllers = [UIViewController]()
    var isFirstControllerInitialize = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        UnsplashImageGetter.shared.addObserver(self, forKeyPath: "arrayOfImagesData", options:[], context: nil)
        
        let timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { (_) in
            guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddView") as? AdvertisementViewController else {
                print("[MainPageViewController] Can't create AdvertisementViewController")
                return
            }
            viewController.url = arrayOfURLs[Int.random(in: 0..<arrayOfURLs.count)]
            self.arrayOfViewControllers.insert(viewController, at: Int.random(in: 0..<self.arrayOfViewControllers.count))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            timer.fire()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "arrayOfImagesData" {
            prepareArrayOfControllers()
            guard let firstViewController = arrayOfViewControllers.first, !isFirstControllerInitialize else {
                return
            }
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
            isFirstControllerInitialize = true
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func prepareArrayOfControllers() {
        guard let image = UnsplashImageGetter.shared.arrayOfImagesData.last, let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageView") as? ImageViewController else {
            print("[MainPageViewController] Can't create ImageViewController")
            return
        }
        if let id = image.id {
            viewController.id = id
        }
        arrayOfViewControllers.append(viewController)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UnsplashImageGetter.shared.removeObserver(self, forKeyPath: "arrayOfImagesData")
    }
}

extension MainPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = arrayOfViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard arrayOfViewControllers.count > previousIndex else {
            return nil
        }
        
        return arrayOfViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = arrayOfViewControllers.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        let arrayCount = arrayOfViewControllers.count
        
        if nextIndex == arrayCount - 1 {
            UnsplashImageGetter.shared.loadNewRandomPhoto()
        }
        
        guard arrayCount != nextIndex else {
            return nil
        }
        
        guard arrayCount > nextIndex else {
            return nil
        }
        
        return arrayOfViewControllers[nextIndex]
    }
    
}
