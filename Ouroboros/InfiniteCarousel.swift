//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

class InfiniteCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBInspectable var buffer = 5
    
    var count = 0
    
    var rootDataSource: UICollectionViewDataSource!
    var rootDelegate: UICollectionViewDelegateFlowLayout!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.dataSource = self
        self.delegate = self
    }
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
        print("shouldUpdateFocusInContext: " + debugFocusChange(context))
        
        let (_, to) = self.convertToIndexPaths(context)
        guard to != nil else {
            return false
        }

        if jumpFromIndex != nil {
            if focusHeading != context.focusHeading {
                // Swapped directions mid jump -- abort
                jumpFromIndex = nil
                jumpToIndex = nil
                jumpToFocusIndex = nil
            }
        }
        
        focusHeading = context.focusHeading
        if focusHeading == .Left {
//            if to!.item < 0 {
//                return false
//            }
            if to!.item < buffer {
                jumpFromIndex = jumpFromIndex ?? to!.item
                jumpToIndex = buffer + count - 1
                jumpToFocusIndex = to!.item + count
                print("Going left, from \(jumpFromIndex!); sending to \(jumpToIndex!); focusing on \(jumpToFocusIndex!)")
            }
        }
        
        if focusHeading == .Right {
//            if to!.item >= 2*buffer + count {
//                return false
//            }
            if to!.item >= buffer + count {
                jumpFromIndex = jumpFromIndex ?? to!.item
                jumpToIndex = buffer
                jumpToFocusIndex = to!.item - count
                print("Going right, from \(jumpFromIndex!); sending to \(jumpToIndex!); focusing on \(jumpToFocusIndex!)")
            }
        }

        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        print("didUpdateFocus: " + debugFocusChange(context))
        
        super.didUpdateFocusInContext(context, withAnimationCoordinator: coordinator)
    }

    
    var jumpFromIndex: Int?
    var jumpToIndex: Int?
    var jumpToFocusIndex: Int?
    var focusHeading: UIFocusHeading?

    var manualFocusCell: NSIndexPath?// = NSIndexPath(forItem: 2, inSection: 0)
    override weak var preferredFocusedView: UIView? {
        if manualFocusCell == nil {
            print("No manual focus; nil preferred focused view")
            return nil
        }
        
        print("I prefer focus on \(manualFocusCell!.item)")
        let path = manualFocusCell!
        manualFocusCell = nil
        jumpFromIndex = nil
        return self.cellForItemAtIndexPath(path)
    }
    
    func convertToIndexPaths(context: UIFocusUpdateContext) -> (from: NSIndexPath?, to: NSIndexPath?) {
        var from: NSIndexPath?
        var to: NSIndexPath?
        if let previouslyFocusedCell = context.previouslyFocusedView as? UICollectionViewCell {
            from = self.indexPathForCell(previouslyFocusedCell)
        }
        if let nextFocusedCell = context.nextFocusedView as? UICollectionViewCell {
            to = self.indexPathForCell(nextFocusedCell)
        }
        return (from: from, to: to)
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        return count + 2 * buffer
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        
        return rootDataSource.collectionView(collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: adjustedIndex, inSection: 0))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(1000, self.frame.size.height)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        return true
    }
    
    var lastOffset: CGFloat = 0
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let jumpIndex = jumpFromIndex else {
            return
        }
        
        // TODO: screen frame - cell width plus margins / 2 ?
        let desiredOffset = CGFloat(jumpIndex) * 1000.0 - 460.0
        let currentOffset = scrollView.contentOffset.x
        
        print("TESTING \(currentOffset) <?> \(desiredOffset) from jump \(jumpIndex)")
        if (focusHeading == .Left  && currentOffset <= desiredOffset) ||
            (focusHeading == .Right && currentOffset >= desiredOffset) {
                
                print("Jumping to \(jumpToIndex!) focusing on \(jumpToFocusIndex!)")
                jumpFromIndex = nil
                
                let jumpPath = NSIndexPath(forItem: jumpToIndex!, inSection: 0)
                scrollToItemAtIndexPath(jumpPath, atScrollPosition: .CenteredHorizontally, animated: false)
                
                manualFocusCell = NSIndexPath(forItem: jumpToFocusIndex!, inSection: 0)
                setNeedsFocusUpdate()
                
        }
    }
    
    private func debugFocusChange(context: UIFocusUpdateContext) -> String {
        let (from, to) = self.convertToIndexPaths(context)
        return "from \(from?.item ?? -1) to \(to?.item ?? 0) heading \(context.focusHeading == .Right ? "right" : "left")"
    }
}

class CenteringFlowLayout: UICollectionViewFlowLayout {
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if let cv = self.collectionView {
            let cvBounds = cv.bounds
            let halfWidth = cvBounds.size.width * 0.5;
            let proposedContentOffsetCenterX = proposedContentOffset.x + halfWidth;
            
            if let attributesForVisibleCells = layoutAttributesForElementsInRect(cvBounds) {
                var candidateAttributes : UICollectionViewLayoutAttributes?
                for attributes in attributesForVisibleCells {
                    if attributes.representedElementCategory != UICollectionElementCategory.Cell {
                        continue
                    }
                    
                    if let candAttrs = candidateAttributes {
                        let a = attributes.center.x - proposedContentOffsetCenterX
                        let b = candAttrs.center.x - proposedContentOffsetCenterX
                        
                        if fabsf(Float(a)) < fabsf(Float(b)) {
                            candidateAttributes = attributes;
                        }
                    }
                    else {
                        candidateAttributes = attributes;
                        continue;
                    }
                }
                return CGPoint(x: candidateAttributes!.center.x - halfWidth, y: proposedContentOffset.y)
            }
        }
        return super.targetContentOffsetForProposedContentOffset(proposedContentOffset)
    }

    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}