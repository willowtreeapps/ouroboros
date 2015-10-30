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
        
        carousel.registerNib(UINib(nibName: "SampleCell", bundle: nil), forCellWithReuseIdentifier: SampleCell.ID)
        carousel2.registerNib(UINib(nibName: "SampleCell", bundle: nil), forCellWithReuseIdentifier: SampleCell.ID)
        natGeo.dataSource = NatGeoDataSource()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SampleCell.ID, forIndexPath: indexPath) as! SampleCell
        cell.color = colors[indexPath.item]
        cell.label.text = "\(indexPath.item)"
        return cell
    }
}

class SampleCell: UICollectionViewCell {
    static let ID = "SampleCell"
    
    @IBOutlet var label: UILabel!
    
    var color: UIColor = .whiteColor() {
        didSet {
            updateBackgroundColor()
        }
    }
    
    func updateBackgroundColor() {
        if focused {
            contentView.backgroundColor = color
        } else {
            contentView.backgroundColor = color.colorWithAlphaComponent(0.25)
        }
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.updateBackgroundColor()
        }, completion: nil)
    }
}

class ImageCell: UICollectionViewCell {
    static let ID = "ImageCell"
    @IBOutlet var imageView: UIImageView!
}

class NatGeoDataSource: NSObject, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // up to 17
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