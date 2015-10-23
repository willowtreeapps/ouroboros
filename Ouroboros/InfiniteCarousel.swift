//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

public class InfiniteCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    /// The number of cells that are generally focused on the screen
    ///
    /// Usually the total number of visible is this many + 2, since the edges are showing slices
    /// of the cells before and after.
    ///
    /// This is used to decide both how many cells to add around the core as a buffer for infinite
    /// scrolling as well as how many cells ahead or behind we allow the user to focus at once.
    @IBInspectable public var onScreenNumber: Int = 1 {
        didSet {
            buffer = onScreenNumber + 1
        }
    }

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

    /// Number of cells to buffer
    public var buffer: Int = 2

    // The data source we use to reference ourselves and then the root data source
    var respondingChainDataSource: InfiniteCarouselDataSource!
    
    // The delegate we use to reference ourselves and then the root delegate
    var respondingChainDelegate: InfiniteCarouselDelegate!
    
    /// Cached count of current number of items
    private var count = 0
    
    /// Cached cell width; set when first cell is requested and expected not to change
    private var cellWidth: CGFloat = 0
    
    /// Cached interitem spacing; set when first cell is requested and expected not to change
    private var interitemSpacing: CGFloat = 0

    /// Whether or not we're cued to jump
    var jump = false
    
    /// Current direction our focus is traveling
    var focusHeading: UIFocusHeading?
    
    /// Cell to focus on if we update focus
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
        return manualFocusCell
    }
    
    override public func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard jump else {
            return
        }
        
        jump = false
        
        let jumpDistance = CGFloat(count) * (cellWidth + interitemSpacing)
        let currentOffset = self.contentOffset.x
        
        if focusHeading == .Left {
            self.setContentOffset(CGPointMake(currentOffset + jumpDistance, self.contentOffset.y), animated: false)
        } else {
            self.setContentOffset(CGPointMake(currentOffset - jumpDistance, self.contentOffset.y), animated: false)
        }

        setNeedsFocusUpdate()
    }
    
    public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        guard let to = context.nextFocusedIndexPath else {
            // Not in our carousel; allow user to exit
            return true
        }
        
        if nextFocusIsTooFarAway(context) {
            return false
        }
        
        if focusHeading == .Left && to.item < buffer {
            jump = true
            manualFocusCell = NSIndexPath(forItem: to.item + count, inSection: 0)
        }
        
        if focusHeading == .Right && to.item >= buffer + count {
            jump = true
            manualFocusCell = NSIndexPath(forItem: to.item - count, inSection: 0)
        }
        
        focusHeading = context.focusHeading
        return true
    }
    
    /// Returns whether or not the focus is "too far away". 
    ///
    /// In this implementation, we're defining the maximum focus distance as roughtly a single 
    /// screen's worth of content.
    func nextFocusIsTooFarAway(context: UICollectionViewFocusUpdateContext) -> Bool {
        var testOffset = self.bounds.width / (CGFloat(onScreenNumber) + 1.0)
        if context.focusHeading == .Right {
            testOffset *= CGFloat(onScreenNumber)
        }
        var testPoint = CGPointMake(self.contentOffset.x + testOffset, self.bounds.height/2)
        
        var testPath: NSIndexPath? = nil
        let step: CGFloat = (context.focusHeading == .Left) ? -10 : 10 // TODO: Is this best?
        while testPath == nil {
            testPath = self.indexPathForItemAtPoint(testPoint)
            testPoint = CGPointMake(testPoint.x + step, testPoint.y)
        }
        
        let to = context.nextFocusedIndexPath!
        return abs(to.item - testPath!.item) > onScreenNumber
    }
    
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