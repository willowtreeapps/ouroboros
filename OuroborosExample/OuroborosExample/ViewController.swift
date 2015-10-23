//
//  ViewController.swift
//  OuroborosExample
//
//  Created by Ian Terrell on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit
import Ouroboros

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var carousel: InfiniteCarousel!
    @IBOutlet weak var carousel2: InfiniteCarousel!
    @IBOutlet weak var natGeo: InfiniteCarousel!
    
    let colors: [UIColor] = [
        .redColor(),
        .orangeColor(),
        .yellowColor(),
        .greenColor(),
        .blueColor(),
        .purpleColor(),
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.registerClass(ColoredCell.self, forCellWithReuseIdentifier: ColoredCell.ID)
        carousel.scrollToItemAtIndexPath(NSIndexPath(forItem: carousel.buffer, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
        
        carousel2.registerClass(ColoredCell.self, forCellWithReuseIdentifier: ColoredCell.ID)
        carousel2.scrollToItemAtIndexPath(NSIndexPath(forItem: carousel.buffer, inSection: 0), atScrollPosition: .Left, animated: false)
        
        natGeo.rootDataSource = NatGeoDataSource()
        natGeo.rootDelegate = self
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ColoredCell.ID, forIndexPath: indexPath)
        cell.contentView.backgroundColor = colors[indexPath.item]
        return cell
    }
}

class ColoredCell: UICollectionViewCell {
    static let ID = "ColoredCellIdentifier"
}

class ImageCell: UICollectionViewCell {
    static let ID = "ImageCell"
    @IBOutlet var imageView: UIImageView!
}

class NatGeoDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6 // up to 17
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ImageCell.ID, forIndexPath: indexPath) as! ImageCell
        let imageNumber = indexPath.item + 1
        let suffix = (imageNumber < 10) ? "0\(imageNumber)" : "\(imageNumber)"
        let image = UIImage(named: "NatGeo\(suffix).jpg")
        cell.imageView.image = image
        return cell
    }
}