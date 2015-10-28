//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

public class InfiniteCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Initialization
    
    /// Override to set delegate in case there is no future specific delegate.
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }

    /// Override to set delegate in case there is no future specific delegate.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public func setup() {
        object_setClass(self.collectionViewLayout, Layout.self)
        self.delegate = self
        setNeedsFocusUpdate()
    }
    
    /// The number of cells that are generally focused on the screen.
    ///
    /// Usually the total number of visible is this many + 2, since the edges are showing slices
    /// of the cells before and after.
    ///
    /// This is used to decide both how many cells to add around the core as a buffer for infinite
    /// scrolling as well as how many cells ahead or behind we allow the user to focus at once.
    @IBInspectable public var itemsPerPage: Int = 1 {
        didSet {
            buffer = itemsPerPage + 1
        }
    }
    
    /// The original data source for the carousel
    public var rootDataSource: UICollectionViewDataSource!
        
    /// The original delegate for the carousel
    public var rootDelegate: UICollectionViewDelegateFlowLayout?
    
    /// The index of the item that is currently in focus.
    ///
    /// The layout uses this to know which page to center in the view.
    public var currentlyFocusedItem: Int = 0
   
    /// Override dataSource to set up our responder chain
    public override weak var dataSource: UICollectionViewDataSource? {
        get {
            return super.dataSource
        }
        set {
            rootDataSource = newValue
            super.dataSource = self
        }
    }

    /// Override delegate to set up our responder chain
    public override weak var delegate: UICollectionViewDelegate? {
        get {
            return super.delegate
        }
        set {
            rootDelegate = newValue as? UICollectionViewDelegateFlowLayout
            super.delegate = self
        }
    }

    /// Number of cells to buffer
    public var buffer: Int = 2
    
    /// Cached count of current number of items
    private var count = 0

    /// Whether or not we're cued to jump
    var jump = false
    
    /// Current direction our focus is traveling
    var focusHeading: UIFocusHeading?
    
    /// Cell to focus on if we update focus
    var manualFocusCell: NSIndexPath?
    
    /// Returns the index path of the root data source item given an index path from this collection
    /// view, which naturally includes the buffer cells.
    public func adjustedIndexPathForIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        return NSIndexPath(forItem: adjustedIndex, inSection: 0)
    }
    
    public override func reloadData() {
        super.reloadData()
        dispatch_async(dispatch_get_main_queue()){
            if let initialOffset = (self.collectionViewLayout as! Layout).offsetForItemAtIndex(self.buffer) {
                self.setContentOffset(CGPointMake(initialOffset,self.contentOffset.y), animated: false)
            }
            
            // Update initial focus to buffer if we have focus currently
            self.currentlyFocusedItem = self.buffer
            self.manualFocusCell = NSIndexPath(forItem: self.currentlyFocusedItem, inSection: 0)
            self.setNeedsFocusUpdate()
        }
    }
    
    /// For the empty case, returns 0. For a non-empty data source, returns the original number
    /// of cells plus the buffer cells.
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        guard count > 0 else {
            return 0
        }
        return count + 2 * buffer
    }
    
    // Pass through to our root data source
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let adjustedPath = adjustedIndexPathForIndexPath(indexPath)
        return rootDataSource.collectionView(collectionView, cellForItemAtIndexPath: adjustedPath)
    }
    
    // If we are jumping, we set the preferred focus here.
    public func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        return manualFocusCell
    }
    
    // If we allow the user to focus on a cell in our buffer region, we set up the jump logic here.
    public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        guard let to = context.nextFocusedIndexPath else {
            // Not in our carousel; allow user to exit
            return true
        }
        
        if nextFocusIsTooFarAway(context) {
            return false
        }
        
        focusHeading = context.focusHeading
        currentlyFocusedItem = to.item
        
        if focusHeading == .Left && to.item < buffer {
            jump = true
            currentlyFocusedItem += count
        }
        
        if focusHeading == .Right && to.item >= buffer + count {
            jump = true
            currentlyFocusedItem -= count
        }
        
        manualFocusCell = NSIndexPath(forItem: currentlyFocusedItem, inSection: 0)
        return true
    }
    
    // If we are currently jumping, we execute it here.
    override public func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard jump else {
            return
        }
        
        jump = false
        
        let jumpDistance = CGFloat(count) * (collectionViewLayout as! Layout).totalItemWidth
        let currentOffset = self.contentOffset.x
        
        if focusHeading == .Left {
            self.setContentOffset(CGPointMake(currentOffset + jumpDistance, self.contentOffset.y), animated: false)
        } else {
            self.setContentOffset(CGPointMake(currentOffset - jumpDistance, self.contentOffset.y), animated: false)
        }
        
        currentlyFocusedItem = manualFocusCell!.item
        setNeedsFocusUpdate()
    }
    
    /// Returns whether or not the focus is "too far away". 
    ///
    /// In this implementation, we're defining the maximum focus distance as roughtly a single 
    /// screen's worth of content.
    func nextFocusIsTooFarAway(context: UICollectionViewFocusUpdateContext) -> Bool {
        var testOffset = self.bounds.width / (CGFloat(itemsPerPage) + 1.0)
        if context.focusHeading == .Right {
            testOffset *= CGFloat(itemsPerPage)
        }
        var testPoint = CGPointMake(self.contentOffset.x + testOffset, self.bounds.height/2)
        
        var testPath: NSIndexPath? = nil
        let step: CGFloat = (context.focusHeading == .Left) ? -10 : 10 // Is this best?
        while testPath == nil {
            testPath = self.indexPathForItemAtPoint(testPoint)
            testPoint = CGPointMake(testPoint.x + step, testPoint.y)
        }
        
        let to = context.nextFocusedIndexPath!
        return abs(to.item - testPath!.item) > itemsPerPage
    }
    
    // MARK: - Layout
    
    class Layout: UICollectionViewFlowLayout {
        var totalItemWidth: CGFloat {
            return itemSize.width + minimumLineSpacing
        }
        
        func offsetForItemAtIndex(index: Int) -> CGFloat? {
            guard let carousel = collectionView as? InfiniteCarousel else {
                preconditionFailure("This layout should only be used by InfiniteCarousel instances")
            }
            
            let pageSize = carousel.itemsPerPage
            let pageIndex = (index / pageSize)
            let firstItemOnPageIndex = pageIndex * pageSize
            let firstItemOnPage = NSIndexPath(forItem: firstItemOnPageIndex, inSection: 0)
            
            guard let cellAttributes = self.layoutAttributesForItemAtIndexPath(firstItemOnPage) else {
                return nil
            }
            
            let offset = ((carousel.bounds.size.width - (CGFloat(pageSize) * totalItemWidth) - minimumLineSpacing) / 2.0) + minimumLineSpacing
            return cellAttributes.frame.origin.x - offset
        }
        
        override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
            let originalOffset = super.targetContentOffsetForProposedContentOffset(proposedContentOffset, withScrollingVelocity: velocity)
            guard let collectionView = self.collectionView else {
                return originalOffset
            }
            guard let carousel = collectionView as? InfiniteCarousel else {
                preconditionFailure("This layout should only be used by InfiniteCarousel instances")
            }
            guard let offset = offsetForItemAtIndex(carousel.currentlyFocusedItem) else {
                return originalOffset
            }
            return CGPoint(x: offset, y: proposedContentOffset.y)
        }
    }
}
