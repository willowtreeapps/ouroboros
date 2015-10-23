//
//  WTACarouselResponderChain.h
//  Ouroboros
//
//  Created by Chris Mays on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

@import UIKit;

@interface WTACarouselResponderChain : NSObject <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@property(nonatomic, weak) id firstResponder;
@property(nonatomic, weak) id secondResponder;

@end
