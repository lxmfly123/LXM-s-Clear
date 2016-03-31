//
//  UIColor+LXMTableViewGestureRecognizerHelper.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@implementation UIColor (LXMTableViewGestureRecognizerHelper)

- (instancetype)colorWithBrightnessCompenent:(CGFloat)brightnessCompenent {
  UIColor *color;
  if (!color) {
    CGFloat hue, saturation, brightness, alpha;
    if ([self getHue:&hue 
          saturation:&saturation 
          brightness:&brightness 
               alpha:&alpha]) {
      color = [UIColor colorWithHue:hue 
                         saturation:saturation 
                         brightness:brightness * brightnessCompenent 
                              alpha:alpha];
    }
  }
  
  if (!color) {
    CGFloat red, green, blue, alpha;
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
      color = [UIColor colorWithRed:red
                              green:green blue:blue alpha:alpha];
    }
  }
  
  if (!color) {
    CGFloat white, alpha;
    if ([self getWhite:&white alpha:&alpha]) {
      color = [UIColor colorWithWhite:white alpha:alpha];
    }
  }
  
  return color;
}

- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset {
  UIColor *color;
  if (!color) {
    CGFloat hue, saturation, brightness, alpha;
    if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
      hue = fmod(hue + hueOffset, 1);
      color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
    }
  }
  return color;
}

@end
