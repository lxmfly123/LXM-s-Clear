//
//  NSArray+LXMTableViewGestureRecognizerHelper.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 5/2/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "NSArray+LXMTableViewGestureRecognizerHelper.h"

@implementation NSArray (LXMTableViewGestureRecognizerHelper)

- (BOOL)has:(NSObject *)object {
  
  __block BOOL has = NO;
  
  [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    if (object == obj) {
      has = YES;
      return;
    }
  }];
  
  return has;
}

@end
