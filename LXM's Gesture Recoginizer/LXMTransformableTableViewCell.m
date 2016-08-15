//
//  LXMTransformableTableViewCell.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 3/24/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTransformableTableViewCell.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"
#import "LXMGlobalSettings.h"
#import "LXMTableViewState.h"

CG_INLINE CGFloat LXMTransformRotationFromHeights(CGFloat h1, CGFloat h2, CGFloat n) {

  CGFloat angle = 0;
  CGFloat part1 = sqrtf(powf(h1, 2) * (powf(h2, 2) - pow(n, 2)) + (powf(h2, 2) * powf(n, 2)));
  CGFloat part2 = h1 * h2;
  CGFloat part3 = n * (h1 + h2);
  angle = 2 * atanf((part1 - part2) / part3);
  return angle;
} ///< 根据变换后的高度反解出变换的角度。

@implementation LXMUnfoldingTransformableTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    self.contentView.layer.sublayerTransform = [LXMGlobalSettings sharedInstance].addingTransform3DIdentity;
    
    self.transformable1HalfView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformable1HalfView.layer.anchorPoint = CGPointMake(0.5, 0);
    self.transformable1HalfView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformable1HalfView];
    
    self.transformable2HalfView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformable2HalfView.layer.anchorPoint = CGPointMake(0.5, 1);
    self.transformable2HalfView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformable2HalfView];

    // 非常重要：self.bakcgroundColor 不能为透明，否则在动画过程中会row之间有大概率会产生细黑条
    self.backgroundColor = [UIColor blackColor];
    self.tintColor = [UIColor whiteColor];

    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor whiteColor];
    
    self.detailTextLabel.backgroundColor = [UIColor clearColor];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  
  return self;
}

- (void)layoutSubviews {
  
  [super layoutSubviews];

  CGSize contentViewSize = self.contentView.frame.size;
  CGFloat labelHeight = self.finishedHeight / 2;
  CGFloat h1 = contentViewSize.height <= self.finishedHeight ? contentViewSize.height / 2 : labelHeight;
  CGFloat fraction = 2 * h1 / self.finishedHeight;

  CGFloat angle = LXMTransformRotationFromHeights(h1, labelHeight, ABS(1.0 / self.contentView.layer.sublayerTransform.m34));

  self.transformable1HalfView.backgroundColor = [self.tintColor lxm_colorWithBrightnessComponent:0.3f + 0.7f * fraction];
  self.transformable2HalfView.backgroundColor = [self.tintColor lxm_colorWithBrightnessComponent:0.5f + 0.5f * fraction];

  self.transformable1HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - h1, contentViewSize.width, labelHeight + 0.5);
  self.transformable2HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - (labelHeight - h1), contentViewSize.width, labelHeight);
  CATransform3D transform1 = CATransform3DMakeRotation(angle, -1, 0, 0);
  CATransform3D transform2 = CATransform3DMakeRotation(angle, 1, 0, 0);
  self.transformable1HalfView.layer.transform = transform1;
  self.transformable2HalfView.layer.transform = transform2;
  
  if ([self.textLabel.text length] > 0) {
    self.detailTextLabel.text = self.textLabel.text;
    self.detailTextLabel.font = self.textLabel.font;
    self.detailTextLabel.textColor = self.textLabel.textColor;
    self.detailTextLabel.textAlignment = self.textLabel.textAlignment;
  }
  
  self.textLabel.frame = CGRectMake([LXMGlobalSettings sharedInstance].textFieldLeftMargin + [LXMGlobalSettings sharedInstance].textFieldLeftPadding, 
                                    0, 
                                    contentViewSize.width - 20.0f,
                                    self.finishedHeight);
  self.detailTextLabel.frame = CGRectOffset(self.textLabel.frame, 0, -self.finishedHeight / 2);
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

@end

@implementation LXMFlippingTransformableTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

  return [self initWithStyle:style anchorPoint:(CGPoint){0.5, 1.0} reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithAnchorPoint:(CGPoint)anchorPoint reuseIdentifier:(NSString *)reuseIdentifier {

  return [self initWithStyle:UITableViewCellStyleDefault anchorPoint:anchorPoint reuseIdentifier:reuseIdentifier];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style anchorPoint:(CGPoint)anchorPoint reuseIdentifier:(NSString *)reuseIdentifier {

  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.contentView.layer.sublayerTransform = [LXMGlobalSettings sharedInstance].addingTransform3DIdentity;
    self.transformableView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformableView.layer.anchorPoint = anchorPoint;
    self.transformableView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformableView];

    // 非常重要：self.bakcgroundColor 不能为透明，否则在动画过程中会row之间有大概率会产生细黑条
    self.backgroundColor = [UIColor blackColor];
    self.tintColor = [UIColor whiteColor];

    self.textLabel.backgroundColor = [UIColor clearColor];
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor whiteColor];

    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  return self;
}

/*
- (void)layoutSubviews {
  
  [super layoutSubviews];
  
  self.fraction = [LXMTableViewState sharedInstance].addingProgress;
  
  CGSize contentViewSize = self.contentView.frame.size;
  CGFloat labelHeight = self.finishedHeight;
  CGFloat angle = acosf(self.fraction);
  
  self.transformableView.backgroundColor = [self.tintColor colorWithBrightnessComponent:0.5f + 0.5f * self.fraction];
  if ([LXMTableViewState sharedInstance].addingProgress < 1) {
    self.transformableView.frame = CGRectMake(0, self.transformableView.frame.size.height - labelHeight, self.frame.size.width, labelHeight);
    CATransform3D identity = CATransform3DIdentity;
    identity.m34 = [LXMGlobalSettings sharedInstance].addingM34;
    CATransform3D transform = CATransform3DRotate(identity, angle, 1, 0, 0);
    self.transformableView.layer.transform = transform;
  } else {
    self.transformableView.frame = CGRectMake(0, self.frame.size.height - labelHeight, self.frame.size.width, labelHeight);
    CATransform3D identity = CATransform3DIdentity;
    identity.m34 = [LXMGlobalSettings sharedInstance].addingM34;
    self.transformableView.layer.transform = identity;
  }
  
  self.textLabel.frame = CGRectMake([LXMGlobalSettings sharedInstance].textFieldLeftMargin + [LXMGlobalSettings sharedInstance].textFieldLeftPadding, 
                                   0, 
                                   contentViewSize.width - 20.0f,
                                   self.finishedHeight);
}*/

- (void)layoutSubviews {

  [super layoutSubviews];

  CGSize contentViewSize = self.contentView.frame.size;
  CGFloat labelHeight = self.finishedHeight;
  CGFloat h1 = contentViewSize.height <= self.finishedHeight ? contentViewSize.height : self.finishedHeight;
  CGFloat angle = LXMTransformRotationFromHeights(h1, labelHeight, ABS(1.0 / self.contentView.layer.sublayerTransform.m34));
  CGFloat fraction = h1 / self.finishedHeight;

  self.transformableView.backgroundColor = [self.tintColor lxm_colorWithBrightnessComponent:0.5f + 0.5f * fraction];
  self.transformableView.frame = self.transformableView.layer.anchorPoint.y < 0.5f ?
                                 CGRectMake(0, 0, contentViewSize.width, labelHeight) :
                                 CGRectMake(0, h1 - labelHeight, contentViewSize.width, labelHeight);
  self.transformableView.layer.transform = CATransform3DMakeRotation(angle, self.transformableView.layer.anchorPoint.y < 0.5f ? -1 : 1, 0, 0);

  self.textLabel.frame =
      CGRectMake([LXMGlobalSettings sharedInstance].textFieldLeftMargin + [LXMGlobalSettings sharedInstance].textFieldLeftPadding,
                 0,
                 contentViewSize.width - 20.0f,
                 self.finishedHeight);
}

- (UILabel *)textLabel {

  UILabel *label = [super textLabel];
  if ([label superview] != self.transformableView) {
    [self.transformableView addSubview:label];
  }

  return label;
}

@end

@implementation LXMTransformableTableViewCell

@synthesize finishedHeight;

+ (instancetype)transformableTableViewCellWithStyle:(LXMTransformableTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {

  LXMTransformableTableViewCell *cell;

  switch (style) {
    case LXMTransformableTableViewCellStyleUnfolding:
      cell = [[LXMUnfoldingTransformableTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                           reuseIdentifier:reuseIdentifier];
      break;

    case LXMTransformableTableViewCellStylePullDown:
      cell = [[LXMFlippingTransformableTableViewCell alloc] initWithAnchorPoint:(CGPoint){0.5, 1.0} reuseIdentifier:reuseIdentifier];
          break;

    case LXMTransformableTableViewCellStylePushDown:
      cell = [[LXMFlippingTransformableTableViewCell alloc] initWithAnchorPoint:(CGPoint){0.5, 0.0} reuseIdentifier:reuseIdentifier];
      break;
  }

  return cell;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
