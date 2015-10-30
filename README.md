# Ouroboros, by WillowTree

### *An infinitely scrolling carousel for tvOS*

## Installation

You can use this project via CocoaPods with:
```ruby
pod 'WillowTreeOuroboros'
```

Without CocoaPods you can simply copy the `InfiniteCarousel.swift` file into
your project.

## Usage

See the enclosed `OuroborosExample` application for a working demo.

If you're using a storyboard, simply change your collection view class to
`InfiniteCarousel` and make sure your layout is set up properly.

From code, use it as you would normally use a `UICollectionView`.

## Notes

* Your carousel will work best if the total number of items you display is evenly
  divisible by the number of items per page (`count % itemsPerPage == 0`).
* This carousel only supports a single section with homogenous sizes and
  interline items.
* The carousel overrides setters to become its own data source and delegate.
  If you need to do any extra datasource or delegate work you must subclass
  and access the `rootDataSource` and `rootDelegate` instances.
* You must use a `UICollectionViewFlowLayout` with the carousel, and you must
  set up the item sizes and line spacing with its instance variables.

### WillowTree is Hiring!

Want to write Go for mobile applications? Want to write anything else for mobile
applications? [Check out our openings!](http://willowtreeapps.com/careers/)
