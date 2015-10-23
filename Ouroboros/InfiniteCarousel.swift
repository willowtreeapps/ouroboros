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
    @IBOutlet public var rootDataSource: UICollectionViewDataSource! {
        didSet {
            respondingChainDataSource = InfiniteCarouselDataSource(firstResponder: self, second: rootDataSource)
            self.dataSource = respondingChainDataSource
        }
    }

    /// The real delegate for the carousel
    @IBOutlet public var rootDelegate: UICollectionViewDelegateFlowLayout! {
        didSet {
            respondingChainDelegate = InfiniteCarouselDelegate(firstResponder: self, second: rootDelegate)
            self.delegate = respondingChainDelegate;
        }
    }
    
    // The data source we use to reference ourselves and then the root data source
    var respondingChainDataSource: InfiniteCarouselDataSource!
    
    // The delegate we use to reference ourselves and then the root delegate
    var respondingChainDelegate: InfiniteCarouselDelegate!
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Cached count of current number of items
    private var count = 0
    
    /// Cached cell width; set when first cell is requested and expected not to change
    private var cellWidth: CGFloat = 0
    
    /// Cached interitem spacing; set when first cell is requested and expected not to change
    private var interitemSpacing: CGFloat = 0
    
    var jumpFromIndex: Int?
    var jumpToIndex: Int?
    var jumpToFocusIndex: Int?
    var focusHeading: UIFocusHeading?
    var manualFocusCell: NSIndexPath?
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        return count + 2 * buffer
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if !cellMetricsCached() {
            cacheCellMetricsWithIndexPath(indexPath)
        }
        
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        
        return rootDataSource.collectionView(collectionView, cellForItemAtIndexPath: NSIndexPath(forItem: adjustedIndex, inSection: 0))
    }
    public func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        assert(collectionView === self)
        return manualFocusCell
    }
    
//    public func collectionView(_ collectionView: UICollectionView,
//        didUpdateFocusInContext context: UICollectionViewFocusUpdateContext,
//        withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
//            
//    }
    
    override public func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard jumpFromIndex != nil else {
            return
        }
        
        jumpFromIndex = nil
        
        let jumpDistance = CGFloat(count) * (cellWidth + interitemSpacing)
        let currentOffset = self.contentOffset.x
        
        if focusHeading == .Left {
            self.setContentOffset(CGPointMake(currentOffset + jumpDistance, self.contentOffset.y), animated: false)
        } else {
            self.setContentOffset(CGPointMake(currentOffset - jumpDistance, self.contentOffset.y), animated: false)
        }

        manualFocusCell = NSIndexPath(forItem: jumpToFocusIndex!, inSection: 0)
        setNeedsFocusUpdate()
    }
    
    public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        guard let to = context.nextFocusedIndexPath else {
            // Not in our carousel; allow user to exit
            return true
        }
        
        // Ensure we're not trying to focus too far away
        var centerPath: NSIndexPath? = nil
        let step: CGFloat = (context.focusHeading == .Left) ? -10 : 10 // TODO: Clean this up
        var testPoint = CGPointMake(self.contentOffset.x + self.bounds.width/2,self.bounds.height/2)
        while centerPath == nil {
            centerPath = self.indexPathForItemAtPoint(testPoint)
            testPoint = CGPointMake(testPoint.x + step, testPoint.y)
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
    
//    public func scrollViewDidScroll(scrollView: UIScrollView) {
//        guard let jumpIndex = jumpFromIndex else {
//            return
//        }
//        
//        // TODO: screen frame - cell width plus margins / 2 ?
//        let desiredOffset = CGFloat(jumpIndex) * (cellWidth + interitemSpacing)
//        let currentOffset = scrollView.contentOffset.x
//        
//        print("looking for \(desiredOffset) currently \(currentOffset)")
//        
//        if (focusHeading == .Left  && currentOffset <= desiredOffset) ||
//            (focusHeading == .Right && currentOffset >= desiredOffset)
//        {
//            // Jump!
//            
//            jumpFromIndex = nil
//            
//            let jumpPath = NSIndexPath(forItem: jumpToIndex!, inSection: 0)
//            scrollToItemAtIndexPath(jumpPath, atScrollPosition: .Left, animated: false)
//            
//            manualFocusCell = NSIndexPath(forItem: jumpToFocusIndex!, inSection: 0)
//            setNeedsFocusUpdate()
//        }
//    }
    
    func cellMetricsCached() -> Bool {
        return cellWidth != 0
    }
    
    func cacheCellMetricsWithIndexPath(indexPath: NSIndexPath) {
        if let size = rootDelegate?.collectionView?(self, layout: collectionViewLayout, sizeForItemAtIndexPath: indexPath) {
            cellWidth = size.width
        } else {
            cellWidth = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize.width
        }
        if cellWidth == 0 {
            preconditionFailure("InfiniteCarousel only be used with a cell width > 0")
        }
        if let lineSpacing = rootDelegate?.collectionView?(self, layout: collectionViewLayout, minimumLineSpacingForSectionAtIndex: indexPath.section) {
            interitemSpacing = lineSpacing
        } else {
            interitemSpacing = (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
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