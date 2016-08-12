//
//  UIColor+LXMTableViewGestureRecognizerHelper.h
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (LXMTableViewGestureRecognizerHelper)

+ (instancetype)lxm_colorBetweenColor:(UIColor *)startColor endColor:(UIColor *)endColor withPercentage:(CGFloat)percentage;

- (instancetype)lxm_colorWithBrightnessComponent:(CGFloat)brightnessComponent;
- (instancetype)lxm_colorWithBrightnessOffset:(CGFloat)brightnessOffset;
- (UIColor *)lxm_colorWithHueOffset:(CGFloat)hueOffset;

@end
