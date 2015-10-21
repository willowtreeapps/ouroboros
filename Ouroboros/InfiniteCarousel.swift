//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

class InfiniteCarousel: UICollectionView {
    
    let count = 6
    let buffer = 2
    
    override func shouldUpdateFocusInContext(context: UIFocusUpdateContext) -> Bool {
//        print("Asking to update \(debugFocusChange(context))")
        let (_, to) = self.convertToIndexPaths(context)
        guard to != nil else {
            print("Asking -- returning false due to no to path")
            return false
        }
        if (to!.item >= 2 * buffer + count - 1) || (to!.item <= buffer - 1) {
            print("Asking -- returning false due to \(to!.item) being out of bounds")
            return false
        }
        return true
    }
    
    override func didUpdateFocusInContext(context: UIFocusUpdateContext,
        withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
            super.didUpdateFocusInContext(context, withAnimationCoordinator: coordinator)
            
//            print("Did update")
            let (_, to) = self.convertToIndexPaths(context)
            guard to != nil else {
//                print("No to path in did Update")
                return
            }
            
//            print("Going from \(debugFocusChange(context))")
            
            let index = to!.item
            let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
            let adjustedIndex = wrapped % count
            
            guard adjustedIndex != (index - buffer) else {
                return
            }
            
            var newIndexPath: NSIndexPath

            if (adjustedIndex < (index - buffer) && context.focusHeading == .Right) {
                newIndexPath = NSIndexPath(forItem: 0 + buffer, inSection: 0)
            } else if (adjustedIndex > (index - buffer) && context.focusHeading == .Left) {
                newIndexPath = NSIndexPath(forItem: count - 1 + buffer, inSection: 0)
            } else {
                return
            }
            
            coordinator.addCoordinatedAnimations(nil) { () -> Void in
                self.manualFocusCell = newIndexPath
                print("Sending to \(newIndexPath.item)")
//                self.scrollToItemAtIndexPath(newIndexPath, atScrollPosition: .CenteredHorizontally, animated: false)
//                self.setNeedsFocusUpdate()
            }
    }
    
//    var jumpFromIndex: Int?
//    var jumpToIndex: Int?
    var manualFocusCell: NSIndexPath?// = NSIndexPath(forItem: 2, inSection: 0)
    override weak var preferredFocusedView: UIView? {
        if manualFocusCell == nil {
            print("No manual focus; nil preferred focused view")
            return nil
        }
        
        print("I prefer focus on \(manualFocusCell!.item)")
        let path = manualFocusCell!
        manualFocusCell = nil
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
    
    func debugFocusChange(context: UIFocusUpdateContext) -> String {
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