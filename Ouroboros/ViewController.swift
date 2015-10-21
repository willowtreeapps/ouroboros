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
    
    let buffer = 2
    
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
//        carousel.scrollToItemAtIndexPath(NSIndexPath(forItem: buffer, inSection: 0), atScrollPosition: .Left, animated: false)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count + 2*buffer
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ColoredCell.ID, forIndexPath: indexPath)
        
        let count = colors.count
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        cell.contentView.backgroundColor = colors[adjustedIndex]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(1000, carousel.frame.size.height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
//        print("asking!")
        return true
    }
    
//    
    var lastOffset: CGFloat = 0
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        guard let jumpIndex = carousel.jumpFromIndex else {
            return
        }
        //        guard let jumpCell = carousel.manualFocusCell else {
        //            return
        //        }
        
        
        // TODO: screen frame - cell width plus margins / 2 ?
        let desiredOffset = CGFloat(jumpIndex) * 1000.0 - 460.0
        let currentOffset = scrollView.contentOffset.x
        
        print("Checking in scroll current: \(currentOffset) vs desired \(desiredOffset)")
        print("Difference is \(desiredOffset - currentOffset)")
        
        
        if (carousel.focusHeading == .Left  && currentOffset <= desiredOffset) ||
           (carousel.focusHeading == .Right && currentOffset >= desiredOffset) {
            
            print("JUMPING TO \(carousel.jumpToIndex!)")
            let jumpPath = NSIndexPath(forItem: carousel.jumpToIndex!, inSection: 0)
            carousel.scrollToItemAtIndexPath(jumpPath, atScrollPosition: .CenteredHorizontally, animated: false)
            
            carousel.manualFocusCell = NSIndexPath(forItem: carousel.jumpToFocusIndex!, inSection: 0)
            carousel.setNeedsFocusUpdate()
            
            carousel.jumpFromIndex = nil
        }
        

    }
        
        
//        print("did scroll yo")
//        updatePageControl(scrollView)
//        handleScrollToEdge(scrollView)
//
//        guard let jumpCell = carousel.manualFocusCell {
//            
//        }
//        
//        lastOffset = scrollView.contentOffset.x
        //                self.scrollToItemAtIndexPath(newIndexPath, atScrollPosition: .CenteredHorizontally, animated: false)
        //                self.setNeedsFocusUpdate()
    
//    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
//        guard let jumpCell = carousel.manualFocusCell else {
//            return
//        }
//        
//        carousel.scrollToItemAtIndexPath(jumpCell, atScrollPosition: .CenteredHorizontally, animated: false)
//        carousel.setNeedsFocusUpdate()
//    }
//    
//    var currentCard = 0
//    func updatePageControl(scrollView: UIScrollView) {
//
//        let point = CGPointMake(scrollView.contentOffset.x + 1000 / 2, 0)
//        print("point for test is \(point) -- offset \(scrollView.contentOffset.x)")
//        if let index = carousel.indexPathForItemAtPoint(point)?.item {
//            if index != currentCard {
//                print("current card is now \(index)")
//                currentCard = index
//            }
//            
//        }
//    }
    
//    func handleScrollToEdge(scrollView: UIScrollView) {
//        guard let jumpIndex = carousel.jumpFromIndex else {
//            return
//        }
////        guard let jumpCell = carousel.manualFocusCell else {
////            return
////        }
//        
//        
//        scrollView.contentOffset.x
//        guard currentCard == jumpIndex else {
//            return
//        }
//        
//        print("JUMPING TO \(carousel.jumpToIndex!)")
//        let jumpPath = NSIndexPath(forItem: carousel.jumpToIndex!, inSection: 0)
//        carousel.manualFocusCell = jumpPath
//        carousel.scrollToItemAtIndexPath(jumpPath, atScrollPosition: .CenteredHorizontally, animated: false)
//        carousel.setNeedsFocusUpdate()
//    }
//        if currentCard =- colors.count - buffer {
//            let newIndexPath = NSIndexPath(forItem: 2, inSection: 0)
//            carousel.scrollToItemAtIndexPath(newIndexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
//            currentCard = 2
//            
//        } else if currentCard == 1 {
//            let newIndexPath = NSIndexPath(forItem: cards.count - 3, inSection: 0)
//            collectionView.scrollToItemAtIndexPath(newIndexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
//            currentCard = cards.count - 3
//        }

    
//    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        print("WHAT ON EARTH IS GOING ON WHEN DO I GET CALLED")
//        
//        guard let jumpCell = carousel.manualFocusCell else {
//            return
//
//        }
//        
//        carousel.scrollToItemAtIndexPath(jumpCell, atScrollPosition: .CenteredHorizontally, animated: false)
//        carousel.setNeedsFocusUpdate()
//    }
    
}

class ColoredCell: UICollectionViewCell {
    static let ID = "ColoredCellIdentifier"
}