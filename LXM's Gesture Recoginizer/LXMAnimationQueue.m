//
//  LXMAnimationQueue.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMAnimationQueue.h"

@interface LXMAnimationQueue ()

@property (nonatomic, strong) NSMutableArray<LXMAnimationBlock> *animations;

@end

@implementation LXMAnimationQueue

- (instancetype)init {
  
  if (self = [super init]) {
    self.animations = [[NSMutableArray alloc] initWithCapacity:5];
  }
  return self;
}

- (void)addAnimations:(LXMAnimationBlock)animation1, ... {
  
  [self.animations addObject:animation1];
  
  va_list animations;
  va_start(animations, animation1);
  [self addAnimations:animation1 withParameters:animations];
  va_end(animations);
}

- (void)addAnimations:(LXMAnimationBlock)animation1 withParameters:(va_list)animations {

  LXMAnimationBlock animation;
  while ((animation = va_arg(animations, LXMAnimationBlock))) {
    [self.animations addObject:animation];
  }
}

- (LXMAnimationBlock (^)(void))blockCompletion {
  
  return ^LXMAnimationBlock {
    if (self.animations.count > 0) {
      LXMAnimationBlock block = self.animations[0];
      [self.animations removeObjectAtIndex:0];
      return block;
    } else {
      if (self.queueCompletion) {
        return self.queueCompletion;
      } else {
        return ^(BOOL finished) {
          NSLog(@"finished");
        };
      }
    }
  };
}

- (void)play {
  self.blockCompletion()(YES);
}

@end