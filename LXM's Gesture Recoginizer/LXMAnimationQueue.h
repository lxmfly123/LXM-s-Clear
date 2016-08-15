//
//  LXMAnimationQueue.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LXMAnimationBlock)(BOOL);

@interface LXMAnimationQueue : NSObject

@property (nonatomic, copy) LXMAnimationBlock (^blockCompletion)(void);
@property (nonatomic, copy) LXMAnimationBlock queueCompletion;

//+ (instancetype)initWithAnimations:(LXMAnimationBlock)animation1, ... NS_REQUIRES_NIL_TERMINATION;

- (void)addAnimations:(LXMAnimationBlock)animation1, ... NS_REQUIRES_NIL_TERMINATION;
- (void)clearQueue;

- (void)play;

@end
