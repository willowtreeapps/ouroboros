# Ouroboros, by WillowTree

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

### *An infinitely scrolling carousel for tvOS*

<img src="https://github.com/willowtreeapps/ouroboros/blob/develop/ouroboros.gif?raw=true">

## Installation

You can use this project via CocoaPods:
```ruby
pod 'WillowTreeOuroboros'
```

Or via Carthage:
```ruby
github "willowtreeapps/ouroboros" >= 0.1
```

Or you can simply copy the `InfiniteCarousel.swift` file into
your project.

## Usage

See the enclosed `OuroborosExample` application for a working demo.

If you're using a storyboard, simply change your collection view class to
`InfiniteCarousel`. Make sure you're using a horizontally scrolling collection
view with a flow layout, and make sure the flow layout's item size and minimum
line spacing are both set.

If you wish to center on more than one item at a time, be sure to update
`itemsPerPage`.

If you wish for the carousel to auto-scroll, set `autoScroll` and the two
related timers (in seconds).

## Notes

* Your carousel will work best if the total number of items you display is evenly
  divisible by the number of items per page (`count % itemsPerPage == 0`).
* This carousel only supports a single section with homogenous sizes and
  interline items.
* This carousel currently only scrolls horizontally.
* The carousel overrides setters to become its own data source and delegate.
  If you need to do any extra datasource or delegate work you must subclass
  and access the `rootDataSource` and `rootDelegate` instances.
* You must use a `UICollectionViewFlowLayout` with the carousel, and you must
  set up the item sizes and line spacing with its instance variables.

### WillowTree is Hiring!

Want to write amazing tvOS apps? Want to write amazing iOS apps?
[Check out our openings!](http://willowtreeapps.com/careers/)
