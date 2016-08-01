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

@implementation LXMUnfoldingTransformableTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = [LXMGlobalSettings sharedInstance].addingM34;
    self.contentView.layer.sublayerTransform = transform;
    
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
    self.textLabel.shadowOffset = CGSizeMake(0, 1);
    self.textLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
  }
  return self;
}

- (void)layoutSubviews {
  
  [super layoutSubviews];
  
  CGFloat fraction = (self.frame.size.height / self.finishedHeight);
  fraction = MAX(MIN(1, fraction), 0);
  CGFloat angle = acosf(fraction);
  CATransform3D transform1 = CATransform3DMakeRotation(angle, -1, 0, 0);
  CATransform3D transform2 = CATransform3DMakeRotation(angle, 1, 0, 0);
  
  self.transformable1HalfView.layer.transform = transform1;
  self.transformable2HalfView.layer.transform = transform2;
    
  self.transformable1HalfView.backgroundColor = [self.tintColor colorWithBrightnessComponent:0.3f + 0.7f * fraction];
  self.transformable2HalfView.backgroundColor = [self.tintColor colorWithBrightnessComponent:0.5f + 0.5f * fraction];
  
  CGSize contentViewSize = self.contentView.frame.size;
  CGFloat labelHeight = self.finishedHeight / 2;

  self.transformable1HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - cosf(angle) * labelHeight, contentViewSize.width, labelHeight + 1);
  self.transformable2HalfView.frame = CGRectMake(0, contentViewSize.height / 2 - labelHeight * (1 - cosf(angle)), contentViewSize.width, labelHeight);
  
  if ([self.textLabel.text length] > 0) {
    self.detailTextLabel.text = self.textLabel.text;
    self.detailTextLabel.font = self.textLabel.font;
    self.detailTextLabel.textColor = self.textLabel.textColor;
    self.detailTextLabel.textAlignment = self.textLabel.textAlignment;
    self.detailTextLabel.shadowColor = self.textLabel.shadowColor;
    self.detailTextLabel.shadowOffset = self.textLabel.shadowOffset;
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

@implementation LXMPullDownTransformableTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    self.transformableView = [[UIView alloc] initWithFrame:self.bounds];
    self.transformableView.layer.anchorPoint = CGPointMake(0.5, 1.0);
    self.transformableView.clipsToBounds = YES;
    [self.contentView addSubview:self.transformableView];
    
//    UIView *testView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
//    testView.tag = 1000;
//    testView.backgroundColor = [UIColor whiteColor];
//    [self.contentView addSubview:testView];
    
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

- (void)prepareForReuse {
  
  [super prepareForReuse];
}

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
      cell = [[LXMPullDownTransformableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:reuseIdentifier];
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
