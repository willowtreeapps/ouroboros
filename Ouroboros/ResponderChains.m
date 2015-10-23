//
//  ResponderChains.m
//  Ouroboros
//
//  Created by Chris Mays on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

#import "ResponderChains.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

@interface ResponderChain ()
@property(nonatomic, weak) id firstResponder;
@property(nonatomic, weak) id secondResponder;
@end

@implementation ResponderChain

- (instancetype)initWithFirstResponder:(id)first second:(id)second
{
    self = [super init];
    if (self)
    {
        self.firstResponder = first;
        self.secondResponder = second;
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([self.firstResponder respondsToSelector:selector])
    {
        return YES;
    }
    
    if ([self.secondResponder respondsToSelector:selector])
    {
        return YES;
    }
    
    return [super respondsToSelector:selector];
}

-(void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self.firstResponder respondsToSelector:[invocation selector]])
    {
        [invocation invokeWithTarget:self.firstResponder];
        return;
    }
    
    if ([self.secondResponder respondsToSelector:[invocation selector]])
    {
        [invocation invokeWithTarget:self.secondResponder];
        return;
    }
    
    [super forwardInvocation:invocation];
}

@end

@implementation InfiniteCarouselDataSource

- (instancetype)initWithFirstResponder:(id)first second:(id)second
{
    return [super initWithFirstResponder:first second:second];
}

@end

@implementation InfiniteCarouselDelegate

- (instancetype)initWithFirstResponder:(id)first second:(id)second
{
    return [super initWithFirstResponder:first second:second];
}

@end

#pragma clang diagnostic pop
