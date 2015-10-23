//
//  ViewController.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var carousel: InfiniteCarousel!
    @IBOutlet weak var carousel2: InfiniteCarousel!
    
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
        carousel2.scrollToItemAtIndexPath(NSIndexPath(forItem: carousel.buffer + 3, inSection: 0), atScrollPosition: .CenteredHorizontally, animated: false)
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