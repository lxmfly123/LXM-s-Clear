//
//  UIColor+LXMTableViewGestureRecognizerHelper.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/25/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@implementation UIColor (LXMTableViewGestureRecognizerHelper)

- (instancetype)colorWithBrightnessComponent:(CGFloat)brightnessComponent {

  UIColor *color;

  if (!color) {
    CGFloat hue, saturation, brightness, alpha;
    if ([self getHue:&hue 
          saturation:&saturation 
          brightness:&brightness 
               alpha:&alpha]) {
      color = [UIColor colorWithHue:hue 
                         saturation:saturation 
                         brightness:brightness * brightnessComponent
                              alpha:alpha];
    }
  }
  
  if (!color) {
    NSLog(@"imreachable code.");
    CGFloat red, green, blue, alpha;
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
      color = [UIColor colorWithRed:red
                              green:green blue:blue alpha:alpha];
    }
  }
  
  if (!color) {
    NSLog(@"imreachable code.");
    CGFloat white, alpha;
    if ([self getWhite:&white alpha:&alpha]) {
      color = [UIColor colorWithWhite:white alpha:alpha];
    }
  }
  
  return color;
}

- (instancetype)colorWithBrightnessOffset:(CGFloat)brightnessOffset {

  UIColor *color;

  if (!color) {
    CGFloat hue, saturation, brightness, alpha;
    if ([self getHue:&hue 
          saturation:&saturation 
          brightness:&brightness 
               alpha:&alpha]) {
      color = [UIColor colorWithHue:hue 
                         saturation:saturation 
                         brightness:brightness + brightnessOffset 
                              alpha:alpha];
    }
  }
  
  if (!color) {
    CGFloat red, green, blue, alpha;
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
      color = [UIColor colorWithRed:red
                              green:green
                               blue:blue
                              alpha:alpha];
    }
  }
  
  if (!color) {
    CGFloat white, alpha;
    if ([self getWhite:&white alpha:&alpha]) {
      color = [UIColor colorWithWhite:white
                                alpha:alpha];
    }
  }
  
  return color;
}

- (UIColor *)colorWithHueOffset:(CGFloat)hueOffset {

  UIColor *color;
  CGFloat hue, saturation, brightness, alpha;

  if ([self getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha]) {
    hue = fmodf(hue + hueOffset, 1);
    color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:alpha];
  }
  return color;
}

+ (instancetype)colorBetweenColor:(UIColor *)startColor endColor:(UIColor *)endColor withPercentage:(CGFloat)percentage {
  
  UIColor *color;
  CGFloat startHue, endHue, hue, saturation, brightness, alpha;
  
  [startColor getHue:&startHue saturation:&saturation brightness:&brightness alpha:&alpha];
  [endColor getHue:&endHue saturation:&saturation brightness:&brightness alpha:&alpha];
  
  hue = startHue + percentage * (endHue - startHue);
  color = [UIColor colorWithHue:hue 
                     saturation:saturation 
                     brightness:brightness 
                          alpha:alpha];
  
  return color;
}

@end
