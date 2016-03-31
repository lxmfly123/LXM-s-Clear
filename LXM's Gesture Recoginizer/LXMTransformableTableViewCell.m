//
//  LXMTransformableTableViewCell.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/24/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTransformableTableViewCell.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"

@implementation LXMUnfoldingTransformableTableViewCell
{
  // TODO: middleLayer is a layer to cover the gap between the 1half and the cell above it while pinching. 
  // remove middlelayer after finish adding a row
//  CALayer *_middleLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1 / 500.0f;
    self.contentView.layer.sublayerTransform = transform;
    
    self.transformable1HalfView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformable1HalfView.layer.anchorPoint = CGPointMake(0.5, 0);
    self.transformable1HalfView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformable1HalfView];
    
    self.transformable2HalfView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformable2HalfView.layer.anchorPoint = CGPointMake(0.5, 1);
    self.transformable2HalfView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformable2HalfView];
    
    // TODO: middleLayer
    
    self.backgroundColor = [UIColor clearColor];
    self.tintColor = [UIColor whiteColor];

    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor whiteColor];
    self.textLabel.shadowOffset = CGSizeMake(0, 1);
    self.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  CGFloat fraction = (self.frame.size.height / self.finishedHeight);
  fraction = MAX(MIN(1, fraction), 0);
  
//  CGFloat angle = (M_PI / 2) * (1 - fraction);
  CGFloat angle = acosf(fraction);
  CATransform3D transform1 = CATransform3DMakeRotation(angle, -1, 0, 0);
  CATransform3D transform2 = CATransform3DMakeRotation(angle, 1, 0, 0);
  self.transformable1HalfView.layer.transform = transform1;
  self.transformable2HalfView.layer.transform = transform2;
  
  self.transformable1HalfView.backgroundColor = [self.tintColor colorWithBrightnessCompenent:0.3 + 0.7 * fraction];
  self.transformable2HalfView.backgroundColor = [self.tintColor colorWithBrightnessCompenent:0.5 + 0.5 * fraction];
  
//  _middleLayer.backgroundColor = self.transformable1HalfView.backgroundColor.CGColor;
  // TODO: 修改显示逻辑
  // 原设计是用两个半高的view来显示cell，但是使用view的性能成本太高，显示内容又无需交互。
  // 可修改为：使用2个半高CATextLayer来显示，执行效率高一些。
  CGSize contentViewSize = self.contentView.frame.size;
  CGFloat labelHeight = self.finishedHeight / 2;
  NSLog(@"contentViewSize: %f", contentViewSize.height);
  
  self.transformable1HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - cosf(angle) * labelHeight, contentViewSize.width, labelHeight + 1);
  self.transformable2HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - labelHeight * (1 - cosf(angle)), contentViewSize.width, labelHeight);

  
//  _middleLayer.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
  
//  if (angle / M_PI_2 < 0.005 && [_middleLayer superlayer] == self.contentView.layer) {
//    [_middleLayer removeFromSuperlayer];
//  } else if (angle / M_PI_2 >= 0.005 && [_middleLayer superlayer] == nil) {
//    [self.contentView.layer addSublayer:_middleLayer];
//  }
  
  if ([self.textLabel.text length] > 0) {
    self.detailTextLabel.text = self.textLabel.text;
    self.detailTextLabel.font = self.textLabel.font;
    self.detailTextLabel.textColor = self.textLabel.textColor;
    self.detailTextLabel.textAlignment = self.textLabel.textAlignment;
    self.detailTextLabel.shadowColor = self.textLabel.shadowColor;
    self.detailTextLabel.shadowOffset = self.textLabel.shadowOffset;
  }
  
  self.textLabel.frame = CGRectMake(10, 0, contentViewSize.width - 20.0, self.finishedHeight);
  self.detailTextLabel.frame = CGRectMake(10, -self.finishedHeight / 2, contentViewSize.width - 20.0, self.finishedHeight);
//  self.textLabel.frame = self.transformable1HalfView.bounds;
//  self.detailTextLabel.frame = self.transformable2HalfView.bounds;
}

- (UILabel *)textLabel {
  UILabel *label = [super textLabel];
  if ([label superview] != self.transformable1HalfView) {
    [self.transformable1HalfView addSubview:label];
  }
  return label;
}

- (UILabel *)detailTextLabel {
  UILabel *label = [super detailTextLabel];
  if ([label superview] != self.transformable2HalfView) {
    [self.transformable2HalfView addSubview:label];
  }
  return label;
}

// TODO: imageview 不知道有什么用

@end

@implementation LXMTransformableTableViewCell

@synthesize finishedHeight;

+ (instancetype)transformableTableViewCellWithStyle:(LXMTansformableTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  switch (style) {
    case LXMTansformableTableViewCellStyleUnfolding:
      return [[LXMUnfoldingTransformableTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
      break;
    default:
      return [[LXMUnfoldingTransformableTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
      break;
      //TODO: pulldowncellclass init
//    case LXMTansformableTableViewCellStylePullDown:
//      return [[LXMUnfolding alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
//      break;
  }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
