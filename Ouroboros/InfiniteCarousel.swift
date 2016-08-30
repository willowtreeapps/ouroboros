//
//  InfiniteCarousel.swift
//  Ouroboros
//
//  Created by Ian Terrell on 10/21/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

import UIKit

public class InfiniteCarousel: UICollectionView, UICollectionViewDataSource {
    
    // MARK: - Initialization
    
    /// Override to set delegate in case there is no future specific delegate.
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setup()
    }

    /// Override to set delegate in case there is no future specific delegate.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        guard collectionViewLayout is UICollectionViewFlowLayout else {
            fatalError("InfiniteCarousel can only be used with UICollectionViewFlowLayout instances")
        }
        object_setClass(collectionViewLayout, Layout.self)
        delegate = self
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
            buffer = itemsPerPage * 2
        }
    }
    
    /// Whether or not to auto-scroll this carousel when the user is not interacting with it.
    @IBInspectable public var autoScroll: Bool = false
    
    /// The time in between auto-scroll events.
    @IBInspectable public var autoScrollTime: Double = 9.0
    
    /// The timer used to control auto-scroll behavior
    var scrollTimer: NSTimer?
    
    /// The original data source for the carousel
    public internal(set) weak var rootDataSource: UICollectionViewDataSource!
        
    /// The original delegate for the carousel
    public internal(set) weak var rootDelegate: UICollectionViewDelegate?
    
    /// The index of the item that is currently in focus.
    ///
    /// The layout uses this to know which page to center in the view.
    public internal(set) var currentlyFocusedItem: Int = 0
   
    /// The index of the item that was in focus when the user began a touch event.
    ///
    /// This is used to determine how far we can advance focus in a single gesture.
    public internal(set) var initiallyFocusedItem: Int?
    
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
            rootDelegate = newValue
            super.delegate = self
        }
    }

    /// Number of cells to buffer
    public internal(set) var buffer: Int = 2
    
    /// Cached count of current number of items
    var count = 0

    /// Whether or not we're cued to jump
    var jumping = false
    
    /// Current direction our focus is traveling
    var focusHeading: UIFocusHeading?
    
    /// Cell to focus on if we update focus
    var manualFocusCell: NSIndexPath?
    
    /// Returns the index path of the root data source item given an index path from this collection
    /// view, which naturally includes the buffer cells.
    public func adjustedIndexPathForIndexPath(indexPath: NSIndexPath) -> NSIndexPath {
        precondition(count >= buffer, "Ouroboros requires at least twice the number of items per page to work properly. For best results: a number that is evenly divisible by the number of items per page.")
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        return NSIndexPath(forItem: adjustedIndex, inSection: 0)
    }
    
    public override func reloadData() {
        super.reloadData()
        
        dispatch_async(dispatch_get_main_queue()) {
            guard self.count > 0 else {
                return
            }
            self.scrollToItem(self.buffer, animated: false)
            self.beginAutoScroll()
        }
    }
    
    // For the empty case, returns 0. For a non-empty data source, returns the original number
    // of cells plus the buffer cells.
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        guard count > 0 else {
            return 0
        }
        return count + 2 * buffer
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let adjustedPath = adjustedIndexPathForIndexPath(indexPath)
        return rootDataSource.collectionView(collectionView, cellForItemAtIndexPath: adjustedPath)
    }
    
    public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        initiallyFocusedItem = currentlyFocusedItem
        super.touchesBegan(touches, withEvent: event)
    }
    
    public override func didUpdateFocusInContext(context: UIFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard jumping else {
            return
        }
        
        jumping = false
        
        if focusHeading == .Left {
            jump(.Forward)
        } else {
            jump(.Backward)
        }
        
        currentlyFocusedItem = manualFocusCell!.item
        setNeedsFocusUpdate()
    }
    
    func scrollToItem(item: Int, animated: Bool) {
        if let initialOffset = (self.collectionViewLayout as! Layout).offsetForItemAtIndex(item) {
            self.setContentOffset(CGPointMake(initialOffset,self.contentOffset.y), animated: animated)
        }
        
        // Update focus element in case we have it
        self.currentlyFocusedItem = item
        self.manualFocusCell = NSIndexPath(forItem: self.currentlyFocusedItem, inSection: 0)
        self.setNeedsFocusUpdate()
    }
    
    // MARK: - Auto Scroll
    
    func beginAutoScroll() {
        guard autoScroll else {
            return
        }
        
        scrollTimer?.invalidate()
        scrollTimer = NSTimer.scheduledTimerWithTimeInterval(autoScrollTime, target: self,
            selector: #selector(scrollToNextPage), userInfo: nil, repeats: true)
    }
    
    func stopAutoScroll() {
        scrollTimer?.invalidate()
    }
    
    func scrollToNextPage() {
        var nextItem = self.currentlyFocusedItem + itemsPerPage
        if nextItem >= buffer + count {
            nextItem -= count
            jump(.Backward)
        }

        scrollToItem(nextItem, animated: true)
    }
    
    // MARK: - Jump Helpers
    
    enum JumpDirection {
        case Forward
        case Backward
    }
    
    func jump(direction: JumpDirection) {
        let currentOffset = self.contentOffset.x
        var jumpOffset = CGFloat(count) * (collectionViewLayout as! Layout).totalItemWidth
        if case .Backward = direction {
            jumpOffset *= -1
        }
        self.setContentOffset(CGPointMake(currentOffset + jumpOffset, self.contentOffset.y),
            animated: false)
    }
    
    // MARK: - Layout
    
    class Layout: UICollectionViewFlowLayout {
        var totalItemWidth: CGFloat {
            return itemSize.width + minimumLineSpacing
        }
        
        var carousel: InfiniteCarousel {
            guard let carousel = collectionView as? InfiniteCarousel else {
                fatalError("This layout should only be used by InfiniteCarousel instances")
            }
            return carousel
        }
        
        func offsetForItemAtIndex(index: Int) -> CGFloat? {
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
            guard let offset = offsetForItemAtIndex(carousel.currentlyFocusedItem) else {
                return super.targetContentOffsetForProposedContentOffset(proposedContentOffset, withScrollingVelocity: velocity)
            }
            return CGPoint(x: offset, y: proposedContentOffset.y)
        }
    }
}

extension InfiniteCarousel: UICollectionViewDelegate {
    // Managing the Selected Cells
    
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldSelectItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath)) ?? true
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didSelectItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldDeselectItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath)) ?? true
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didDeselectItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    // Managing Cell Highlighting
    
    public func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldHighlightItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath)) ?? true
    }

    public func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didHighlightItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didUnhighlightItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    // Tracking the Addition and Removal of Views
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, willDisplayCell: cell, forItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, atIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
        rootDelegate?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, atIndexPath: adjustedIndexPathForIndexPath(indexPath))
    }
    
    // Handling Layout Changes
    
    public func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout {
        return rootDelegate?.collectionView?(collectionView, transitionLayoutForOldLayout: fromLayout, newLayout: toLayout) ?? UICollectionViewTransitionLayout(currentLayout: fromLayout, nextLayout: toLayout)
    }
    
    public func collectionView(collectionView: UICollectionView, targetIndexPathForMoveFromItemAtIndexPath originalIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
        return rootDelegate?.collectionView?(collectionView, targetIndexPathForMoveFromItemAtIndexPath: originalIndexPath, toProposedIndexPath: proposedIndexPath) ?? proposedIndexPath
    }
    
    public func collectionView(collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return rootDelegate?.collectionView?(collectionView, targetContentOffsetForProposedContentOffset: proposedContentOffset) ?? proposedContentOffset
    }
    
    // Managing Actions for Cells
    
    public func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldShowMenuForItemAtIndexPath: indexPath) ?? false
    }
    
    public func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return rootDelegate?.collectionView?(collectionView, canPerformAction: action, forItemAtIndexPath: indexPath, withSender: sender) ?? false
    }
    
    public func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        rootDelegate?.collectionView?(collectionView, performAction: action, forItemAtIndexPath: indexPath, withSender: sender)
    }
    
    // Managing Focus in a Collection View
    
    public func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, canFocusItemAtIndexPath: indexPath) ?? collectionView.allowsSelection
    }
    
    public func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        rootDelegate?.collectionView?(collectionView, didUpdateFocusInContext: context, withAnimationCoordinator: coordinator)
    }
    
    public func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath? {
        return manualFocusCell
    }
    
    public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool {
        // Allow users to leave
        guard let to = context.nextFocusedIndexPath else {
            beginAutoScroll()
            return true
        }
        
        // Allow users to enter
        guard context.previouslyFocusedIndexPath != nil else {
            stopAutoScroll()
            return true
        }
        
        // Restrict movement to a page at a time if we're swiping, but don't break
        // keyboard access in simulator.
        if initiallyFocusedItem != nil && abs(to.item - initiallyFocusedItem!) > itemsPerPage {
            return false
        }
        
        focusHeading = context.focusHeading
        currentlyFocusedItem = to.item
        
        if focusHeading == .Left && to.item < buffer {
            jumping = true
            currentlyFocusedItem += count
        }
        
        if focusHeading == .Right && to.item >= buffer + count {
            jumping = true
            currentlyFocusedItem -= count
        }
        
        manualFocusCell = NSIndexPath(forItem: currentlyFocusedItem, inSection: 0)
        return rootDelegate?.collectionView?(collectionView, shouldUpdateFocusInContext: context) ?? true
    }
}
