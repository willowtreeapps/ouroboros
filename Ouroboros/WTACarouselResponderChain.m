//
//  WTACarouselResponderChain.m
//  Ouroboros
//
//  Created by Chris Mays on 10/23/15.
//  Copyright © 2015 WillowTree Apps. All rights reserved.
//

#import "WTACarouselResponderChain.h"

@implementation WTACarouselResponderChain

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([self.firstResponder respondsToSelector:selector])
    {
        return YES;
    }
    else if ([self.secondResponder respondsToSelector:selector])
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
    }
    else if ([self.secondResponder respondsToSelector:[invocation selector]])
    {
             
        [invocation invokeWithTarget:self.secondResponder];
    }
    else
    {
        [super forwardInvocation:invocation];
    }
}

@end
