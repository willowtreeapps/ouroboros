//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

public class InfiniteCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// The number of cells to show on either end of the core datasource cells
    @IBInspectable public var buffer: Int = 2
    
    /// The number of cells ahead of the currently centered one to allow focus on
    @IBInspectable public var focusAheadLimit: Int = 1

    /*
     * To connect protocol-typed outlets in IB, change them to AnyObject! temporarily.
     */
    
    /// The real data source for the carousel
    @IBOutlet public var rootDataSource: UICollectionViewDataSource!

    /// The real delegate for the carousel
    @IBOutlet public var rootDelegate: UICollectionViewDelegateFlowLayout!
    
    // The data source we use to reference ourselves and then the root data source
    var respondingChainDataSource: InfiniteCarouselDataSource!
    
    // The delegate we use to reference ourselves and then the root delegate
    var respondingChainDelegate: InfiniteCarouselDelegate!
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Cached count of current number of items
    private var count = 0
    
    var jumpFromIndex: Int?
    var jumpToIndex: Int?
    var jumpToFocusIndex: Int?
    var focusHeading: UIFocusHeading?
    var manualFocusCell: NSIndexPath?

    override public func awakeFromNib() {
        respondingChainDataSource = InfiniteCarouselDataSource(firstResponder: self, second: rootDataSource)
        self.dataSource = respondingChainDataSource
        
        respondingChainDelegate = InfiniteCarouselDelegate(firstResponder: self, second: rootDelegate)
        self.delegate = respondingChainDelegate;
    }
    
    override public weak var preferredFocusedView: UIView? {
        guard let path = manualFocusCell else {
            return nil
        }
        manualFocusCell = nil
        return self.cellForItemAtIndexPath(path)
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        return count + 2 * buffer
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        
        return rootDataSource.collectionView(collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: adjustedIndex, inSection: 0))
    }
    
    public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        guard let to = context.nextFocusedIndexPath else {
            // Not in our carousel; allow user to exit
            return true
        }
        
        // Ensure we're not trying to focus too far away
        let testPoint = CGPointMake(self.contentOffset.x + self.bounds.width/2,self.bounds.height/2)
        let centerPath = self.indexPathForItemAtPoint(testPoint)
        if centerPath == nil {
            fatalError("todo: test center + interitem space + 1? testpoint: \(testPoint)")
        }
        if abs(to.item - centerPath!.item) > focusAheadLimit {
            return false
        }
        
        if jumpFromIndex != nil && focusHeading != context.focusHeading {
            // Swapped directions mid jump -- abort
            jumpFromIndex = nil
            jumpToIndex = nil
            jumpToFocusIndex = nil
        }
        
        focusHeading = context.focusHeading
        
        if focusHeading == .Left && to.item < buffer {
            jumpFromIndex = jumpFromIndex ?? to.item
            jumpToIndex = buffer + count - 1
            jumpToFocusIndex = to.item + count
        }
        
        if focusHeading == .Right && to.item >= buffer + count {
            jumpFromIndex = jumpFromIndex ?? to.item
            jumpToIndex = buffer
            jumpToFocusIndex = to.item - count
        }
        
        return true
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard let jumpIndex = jumpFromIndex else {
            return
        }
        
        // TODO: screen frame - cell width plus margins / 2 ?
        let desiredOffset = CGFloat(jumpIndex) * 1000.0 - 460.0
        let currentOffset = scrollView.contentOffset.x
        
        if (focusHeading == .Left  && currentOffset <= desiredOffset) ||
            (focusHeading == .Right && currentOffset >= desiredOffset)
        {
            // Jump!
            
            jumpFromIndex = nil
            
            let jumpPath = NSIndexPath(forItem: jumpToIndex!, inSection: 0)
            scrollToItemAtIndexPath(jumpPath, atScrollPosition: .CenteredHorizontally, animated: false)
            
            manualFocusCell = NSIndexPath(forItem: jumpToFocusIndex!, inSection: 0)
            setNeedsFocusUpdate()
        }
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