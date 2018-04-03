/*
 Copyright (c) 2015 WillowTree, Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import UIKit

open class InfiniteCarousel: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        super.delegate = self
        setNeedsFocusUpdate()
    }

    /// The number of cells that are generally focused on the screen.
    ///
    /// Usually the total number of visible is this many + 2, since the edges are showing slices
    /// of the cells before and after.
    ///
    /// This is used to decide both how many cells to add around the core as a buffer for infinite
    /// scrolling as well as how many cells ahead or behind we allow the user to focus at once.
    @IBInspectable open var itemsPerPage: Int = 1 {
        didSet {
            buffer = itemsPerPage * 2
        }
    }

    /// Whether or not to auto-scroll this carousel when the user is not interacting with it.
    @IBInspectable open var autoScroll: Bool = false

    /// The time in between auto-scroll events.
    @IBInspectable open var autoScrollTime: Double = 9.0

    /// The timer used to control auto-scroll behavior
    var scrollTimer: Timer?

    /// The original data source for the carousel
    open internal(set) weak var rootDataSource: UICollectionViewDataSource!

    /// The original delegate for the carousel
    open internal(set) weak var rootDelegate: UICollectionViewDelegate?

    /// The index of the item that is currently in focus.
    ///
    /// The layout uses this to know which page to center in the view.
    open internal(set) var currentlyFocusedItem: Int = 0

    /// The index of the item that was in focus when the user began a touch event.
    ///
    /// This is used to determine how far we can advance focus in a single gesture.
    open internal(set) var initiallyFocusedItem: Int?

    /// Override dataSource to set up our responder chain
    open override weak var dataSource: UICollectionViewDataSource? {
        get {
            return super.dataSource
        }
        set {
            rootDataSource = newValue
            super.dataSource = self
        }
    }

    /// Override delegate to set up our responder chain
    open override weak var delegate: UICollectionViewDelegate? {
        get {
            return super.delegate
        }
        set {
            rootDelegate = newValue
            super.delegate = self
        }
    }

    /// Number of cells to buffer
    open internal(set) var buffer: Int = 2

    /// Cached count of current number of items
    var count = 0

    /// Whether or not we're cued to jump
    var jumping = false

    /// Current direction our focus is traveling
    var focusHeading: UIFocusHeading?

    /// Cell to focus on if we update focus
    var manualFocusCell: IndexPath?

    var shouldEnableInfiniteScroll : Bool {
        return count >= buffer
    }

    /// Returns the index path of the root data source item given an index path from this collection
    /// view, which naturally includes the buffer cells.
    open func adjustedIndexPathForIndexPath(_ indexPath: IndexPath) -> IndexPath {
        if !shouldEnableInfiniteScroll {
            return indexPath
        }
        let index = indexPath.item
        let wrapped = (index - buffer < 0) ? (count + (index - buffer)) : (index - buffer)
        let adjustedIndex = wrapped % count
        return IndexPath(item: adjustedIndex, section: 0)
    }

    open override func reloadData() {
        super.reloadData()

        DispatchQueue.main.async {
            guard self.count > 0 else {
                return
            }
            if self.shouldEnableInfiniteScroll {
                self.scrollToItem(self.buffer, animated: false)
            } else {
                self.scrollToItem(0, animated: false)
            }
            self.beginAutoScroll()
        }
    }

    // For the empty case, returns 0. For a non-empty data source, returns the original number
    // of cells plus the buffer cells.
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        count = rootDataSource.collectionView(collectionView, numberOfItemsInSection: section)
        guard count > 0 else {
            return 0
        }
        if shouldEnableInfiniteScroll {
            return count + 2 * buffer
        } else {
            return count
        }
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if shouldEnableInfiniteScroll {
            let adjustedPath = adjustedIndexPathForIndexPath(indexPath)
            return rootDataSource.collectionView(collectionView, cellForItemAt: adjustedPath)
        } else {
            return rootDataSource.collectionView(collectionView, cellForItemAt: indexPath)
        }
    }


    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        initiallyFocusedItem = currentlyFocusedItem
        super.touchesBegan(touches, with: event)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldHighlightItemAt: indexPath) ?? true
    }

    open func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didHighlightItemAt: indexPath)
    }
    open func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didUnhighlightItemAt: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldSelectItemAt:indexPath) ?? true
    }

    open func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldDeselectItemAt: indexPath) ?? true
    }

    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didDeselectItemAt: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, at indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, at: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        rootDelegate?.collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, at: indexPath)
    }

    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, shouldShowMenuForItemAt: indexPath) ?? true
    }

    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return rootDelegate?.collectionView?(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender) ?? false
    }

    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
         rootDelegate?.collectionView?(collectionView, performAction: action, forItemAt: indexPath, withSender:sender)
    }

    open func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return rootDelegate?.collectionView?(collectionView, canFocusItemAt: indexPath) ?? true
    }

    open func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        var result = rootDelegate?.collectionView?(collectionView, shouldUpdateFocusIn: context) ?? true

        // Allow users to leave
        guard let to = context.nextFocusedIndexPath else {
            beginAutoScroll()
            return result
        }

        // Allow users to enter
        guard context.previouslyFocusedIndexPath != nil else {
            stopAutoScroll()
            return result
        }

        // Restrict movement to a page at a time if we're swiping, but don't break
        // keyboard access in simulator.
        if initiallyFocusedItem != nil && abs(to.item - initiallyFocusedItem!) > itemsPerPage {
            return false
        }

        focusHeading = context.focusHeading
        currentlyFocusedItem = to.item

        if shouldEnableInfiniteScroll {
            if focusHeading == .left && to.item < buffer {
                jumping = true
                currentlyFocusedItem += count
            }

            if focusHeading == .right && to.item >= buffer + count {
                jumping = true
                currentlyFocusedItem -= count
            }
            manualFocusCell = IndexPath(item: currentlyFocusedItem, section: 0)
        } else {
            manualFocusCell = IndexPath(item: to.item, section: 0)
        }
        return result
    }

    open func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        rootDelegate?.collectionView?(collectionView, didUpdateFocusIn: context, with: coordinator)
    }

    open func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return rootDelegate?.indexPathForPreferredFocusedView?(in: collectionView) ?? manualFocusCell
    }

    open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        guard jumping else {
            return
        }

        jumping = false

        if focusHeading == .left {
            jump(.forward)
        } else {
            jump(.backward)
        }

        currentlyFocusedItem = manualFocusCell!.item
        setNeedsFocusUpdate()
    }

    func scrollToItem(_ item: Int, animated: Bool) {
        if let initialOffset = (self.collectionViewLayout as! Layout).offsetForItemAtIndex(item) {
            self.setContentOffset(CGPoint(x: initialOffset,y: self.contentOffset.y), animated: animated)
        }

        // Update focus element in case we have it
        self.currentlyFocusedItem = item
        self.manualFocusCell = IndexPath(item: self.currentlyFocusedItem, section: 0)
        self.setNeedsFocusUpdate()
    }

    // MARK: - Auto Scroll

    func beginAutoScroll() {
        guard autoScroll else {
            return
        }

        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(timeInterval: autoScrollTime, target: self,
                                           selector: #selector(scrollToNextPage), userInfo: nil, repeats: true)
    }

    func stopAutoScroll() {
        scrollTimer?.invalidate()
    }

    @objc func scrollToNextPage() {
        var nextItem = self.currentlyFocusedItem + itemsPerPage
        if nextItem >= buffer + count {
            nextItem -= count
            jump(.backward)
        }

        if !shouldEnableInfiniteScroll && nextItem >= count {
            scrollToItem(0, animated: true)
        } else {
            scrollToItem(nextItem, animated: true)
        }
    }

    // MARK: - Jump Helpers

    enum JumpDirection {
        case forward
        case backward
    }

    func jump(_ direction: JumpDirection) {
        let currentOffset = self.contentOffset.x
        var jumpOffset = CGFloat(count) * (collectionViewLayout as! Layout).totalItemWidth
        if case .backward = direction {
            jumpOffset *= -1
        }
        self.setContentOffset(CGPoint(x: currentOffset + jumpOffset, y: self.contentOffset.y),
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

        func offsetForItemAtIndex(_ index: Int) -> CGFloat? {
            let pageSize = carousel.itemsPerPage
            let pageIndex = (index / pageSize)
            let firstItemOnPageIndex = pageIndex * pageSize
            let firstItemOnPage = IndexPath(item: firstItemOnPageIndex, section: 0)

            guard let cellAttributes = self.layoutAttributesForItem(at: firstItemOnPage) else {
                return nil
            }

            let offset = ((carousel.bounds.size.width - (CGFloat(pageSize) * totalItemWidth) - minimumLineSpacing) / 2.0) + minimumLineSpacing
            return cellAttributes.frame.origin.x - offset
        }

        override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
            guard let offset = offsetForItemAtIndex(carousel.currentlyFocusedItem) else {
                return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
            }
            return CGPoint(x: offset, y: proposedContentOffset.y)
        }
    }
}
