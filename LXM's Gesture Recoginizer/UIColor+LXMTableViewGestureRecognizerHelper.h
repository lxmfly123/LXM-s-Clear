//
//  UIColor+LXMTableViewGestureRecognizerHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LXMTableViewGestureRecognizerHelper)

- (instancetype)colorWithBrightnessCompenent:(CGFloat)brightnessCompenent;
- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset;

@end
