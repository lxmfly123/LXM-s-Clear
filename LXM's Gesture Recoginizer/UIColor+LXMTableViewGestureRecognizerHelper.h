//
//  UIColor+LXMTableViewGestureRecognizerHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LXMTableViewGestureRecognizerHelper)

+ (instancetype)colorBetweenColor:(UIColor *)startColor endColor:(UIColor *)endColor withPercentage:(CGFloat)percentage;

- (instancetype)colorWithBrightnessCompenent:(CGFloat)brightnessCompenent;
- (instancetype)colorWithBrightnessOffset:(CGFloat)brightnessOffset;
- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset;

@end
