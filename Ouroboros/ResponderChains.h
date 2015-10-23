//
//  ResponderChains.h
//  Ouroboros
//
//  Created by Chris Mays on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ResponderChain : NSObject
- (instancetype)initWithFirstResponder:(NSObject*)first
                                second:(NSObject*)second
                                NS_DESIGNATED_INITIALIZER;
@end

@interface InfiniteCarouselDataSource : ResponderChain <UICollectionViewDataSource>
- (instancetype)initWithFirstResponder:(NSObject<UICollectionViewDataSource>*)first
                                second:(NSObject<UICollectionViewDataSource>*)second
                                NS_DESIGNATED_INITIALIZER;
@end

@interface InfiniteCarouselDelegate : ResponderChain <UICollectionViewDelegateFlowLayout>
- (instancetype)initWithFirstResponder:(NSObject<UICollectionViewDelegateFlowLayout>*)first
                                second:(NSObject<UICollectionViewDelegateFlowLayout>*)second
                                NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END