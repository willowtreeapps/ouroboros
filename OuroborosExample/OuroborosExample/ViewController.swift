//
//  ViewController.swift
//  OuroborosExample
//
//  Created by Ian Terrell on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit
import WillowTreeOuroboros

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var carousel: InfiniteCarousel!
    @IBOutlet weak var carousel2: InfiniteCarousel!
    @IBOutlet weak var natGeo: InfiniteCarousel!
    
    let natGeoDataSource = NatGeoDataSource()
    
    let colors: [UIColor] = [
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        carousel.register(UINib(nibName: "SampleCell", bundle: nil), forCellWithReuseIdentifier: SampleCell.ID)
        carousel2.register(UINib(nibName: "SampleCell", bundle: nil), forCellWithReuseIdentifier: SampleCell.ID)
        
        natGeo.dataSource = natGeoDataSource
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SampleCell.ID, for: indexPath) as! SampleCell
        cell.color = colors[indexPath.item]
        cell.label.text = "\(indexPath.item)"
        return cell
    }
}

class SampleCell: UICollectionViewCell {
    static let ID = "SampleCell"
    
    @IBOutlet var label: UILabel!
    
    var color: UIColor = .white {
        didSet {
            updateBackgroundColor()
        }
    }
    
    func updateBackgroundColor() {
        if isFocused {
            contentView.backgroundColor = color
        } else {
            contentView.backgroundColor = color.withAlphaComponent(0.25)
        }
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10 // up to 17
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.ID, for: indexPath) as! ImageCell
        let imageNumber = indexPath.item + 1
        let suffix = (imageNumber < 10) ? "0\(imageNumber)" : "\(imageNumber)"
        let image = UIImage(named: "NatGeo\(suffix).jpg")
        cell.imageView.image = image
        return cell
    }
}
