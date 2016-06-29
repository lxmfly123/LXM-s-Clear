//
//  LXMTableViewCell.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/9/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMTableViewCell.h"
#import "UIColor+LXMTableViewGestureRecognizerHelper.h"
#import "LXMStrikeThroughText.h"
#import "LXMGlobalSettings.h"

typedef NS_ENUM(NSUInteger, LXMTableViewRowGestureHintType) {
  LXMTableViewRowGestureHintCompletion,
  LXMTableViewRowGestureHintDeletion,
};

static CGFloat kLeftMargin = 16.0f;
static CGFloat kRightMargin = 16.0f;

@interface LXMTableViewCell () <UITextFieldDelegate>

@property (nonatomic, strong) UILabel *gestureCompletionHintLabel;
@property (nonatomic, strong) UILabel *gestureDeletionHintLabel;
@property (nonatomic, strong) CAGradientLayer *separationLineLayer;
@property (nonatomic, assign) CGFloat gestureHintWidth;
@property (nonatomic, strong) UIColor *lastBackgroundColor;

@end

@implementation LXMTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    // self
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor blackColor];
    self.contentView.backgroundColor = [UIColor blackColor];
    self.editingState = LXMTableViewCellEditingStateNone;
    
    // actual content view
    self.actualContentView = [[UIView alloc] initWithFrame:CGRectNull];
    [self.contentView addSubview:self.actualContentView];
    
    // separate line
    self.separationLineLayer = [CAGradientLayer new];
    self.separationLineLayer.colors = 
      @[(id)[UIColor colorWithWhite:1.0f alpha:0.0f].CGColor, 
        (id)[UIColor colorWithWhite:1.0f alpha:0.0f].CGColor, 
        (id)[UIColor clearColor].CGColor, 
        (id)[UIColor colorWithWhite:0.0f alpha:0.1f].CGColor];
    self.separationLineLayer.locations = @[@0.0f, @0.01f, @0.98f, @1.0f];
    [self.actualContentView.layer addSublayer:self.separationLineLayer];
    
    // gesture hint labels
    self.gestureCompletionHintLabel = [self labelForGestureHint:LXMTableViewRowGestureHintCompletion];
    [self.contentView insertSubview:self.gestureCompletionHintLabel belowSubview:self.actualContentView];
    
    self.gestureDeletionHintLabel = [self labelForGestureHint:LXMTableViewRowGestureHintDeletion];
    [self.contentView insertSubview:self.gestureDeletionHintLabel belowSubview:self.actualContentView];
    
    // strike through label
    self.strikeThroughText = [[LXMStrikeThroughText alloc] initWithFrame:CGRectNull];
    self.strikeThroughText.delegate = self;
    self.strikeThroughText.isStrikeThrough = self.todoItem.isCompleted;
    [self.actualContentView addSubview:self.strikeThroughText];
    self.strikeThroughText.parentCell = self;
  }
  return self;
}

- (void)layoutGestureHintLabels {
  
  self.gestureCompletionHintLabel.frame = 
  CGRectMake([self gestureHintOffset:LXMTableViewRowGestureHintCompletion].x, 
             [self gestureHintOffset:LXMTableViewRowGestureHintCompletion].y, 
             [self gestureHintWidth], 
             self.bounds.size.height - [self gestureHintOffset:LXMTableViewRowGestureHintCompletion].y * 2);
  self.gestureCompletionHintLabel.textColor = [self gestureHintColor:LXMTableViewRowGestureHintCompletion];
  
  self.gestureDeletionHintLabel.frame = 
  CGRectMake([self gestureHintOffset:LXMTableViewRowGestureHintDeletion].x, 
             [self gestureHintOffset:LXMTableViewRowGestureHintDeletion].y, 
             [self gestureHintWidth], 
             self.bounds.size.height - [self gestureHintOffset:LXMTableViewRowGestureHintDeletion].y * 2);
  self.gestureDeletionHintLabel.textColor = [self gestureHintColor:LXMTableViewRowGestureHintDeletion];
}

- (void)layoutSubviews {
  
  [super layoutSubviews];
  
  if (self.editingState == LXMTableViewCellEditingStateNone) {
    self.actualContentView.frame = self.bounds;
  }
  
  self.separationLineLayer.frame = self.actualContentView.bounds;
  
  [self layoutGestureHintLabels];
  
  self.strikeThroughText.frame = CGRectMake(kLeftMargin, 0, self.bounds.size.width - kLeftMargin - kRightMargin, self.bounds.size.height);
  
  [self.strikeThroughText setNeedsLayout];
}

- (void)prepareForReuse {
  
  self.userInteractionEnabled = YES;
}

- (CGFloat)gestureHintWidth {
  return [LXMGlobalSettings sharedInstance].editCommitTriggerWidth;
}

- (CGFloat)gestureHintColorAlphaComponent {
  
  // it is from 0.0 to 1.0
  CGFloat component = ABS(self.actualContentView.frame.origin.x) / self.gestureHintWidth;
  return component;
}

- (UIColor *)gestureHintColor:(LXMTableViewRowGestureHintType)hintType {
  
  switch (hintType) {
    case LXMTableViewRowGestureHintCompletion:
    {
      if (self.actualContentView.frame.origin.x >[[LXMGlobalSettings sharedInstance] editCommitTriggerWidth]) {
        return [UIColor colorWithHue:107 / 360.0f saturation:1 brightness:1 alpha:1];
      } else {
        if (self.todoItem.isCompleted) {
          return [UIColor grayColor];
        }
        return [UIColor whiteColor];
      }
    }
      break;
      
    case LXMTableViewRowGestureHintDeletion:
    {
      if (ABS(self.actualContentView.frame.origin.x) >[[LXMGlobalSettings sharedInstance] editCommitTriggerWidth]) {
        return [UIColor colorWithHue:1 saturation:1 brightness:1 alpha:1];
      } else {
        if (self.todoItem.isCompleted) {
          return [UIColor grayColor];
        }
        return [UIColor whiteColor];
      }
    }
      break;
  }
}

- (CGPoint)gestureHintOffset:(LXMTableViewRowGestureHintType)hintType {
  
  switch (hintType) {
    case LXMTableViewRowGestureHintCompletion:
      return (CGPoint){MAX(self.actualContentView.frame.origin.x - self.gestureHintWidth, 0), 5};
      break;
      
    case LXMTableViewRowGestureHintDeletion:
      return (CGPoint){MIN((self.bounds.size.width - self.gestureHintWidth) + (self.actualContentView.frame.origin.x + self.gestureHintWidth), self.bounds.size.width - self.gestureHintWidth), 5};
      break;
  }
}

- (void)recoverCellAfterEdit {
  
  self.gestureCompletionHintLabel.hidden = YES;
  self.gestureDeletionHintLabel.hidden = YES;
  
//  self.strikeThroughText
}

- (UILabel *)labelForGestureHint:(LXMTableViewRowGestureHintType)hintType {
  UILabel *label = [[UILabel alloc] initWithFrame:CGRectNull];
  label.backgroundColor = [UIColor blackColor];
  label.font = [UIFont boldSystemFontOfSize:40];
  label.textColor = [UIColor whiteColor];
  switch (hintType) {
    case LXMTableViewRowGestureHintCompletion:
      label.text = @"\u2713";
      [label setTextAlignment:NSTextAlignmentRight];
      break;
    case LXMTableViewRowGestureHintDeletion:
      label.text = @"\u2717";
      [label setTextAlignment:NSTextAlignmentLeft];
      break;
  }
  return label;
}

- (void)saveLastStates {
  
  self.lastBackgroundColor = self.actualContentView.backgroundColor;
}

- (void)updateViewBackgroundColorWithPercentage:(CGFloat)percentage {
  self.actualContentView.backgroundColor = [UIColor colorBetweenColor:self.lastBackgroundColor endColor:self.targetColor withPercentage:percentage];
}

#pragma mark -  getters & setters

- (void)setTodoItem:(LXMTodoItem *)todoItem {
  
  _todoItem = todoItem;
  _strikeThroughText.isStrikeThrough = _todoItem.isCompleted;
  _strikeThroughText.text = _todoItem.text;
}

- (void)setLastBackgroundColor:(UIColor *)lastBackgroundColor {
  
  if (!_lastBackgroundColor) {
    _lastBackgroundColor = [UIColor clearColor];
  }
  _lastBackgroundColor = lastBackgroundColor;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  
  return YES && [self.delegate tableViewCellShouldBeginTextEditing:self];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  
  [self.delegate tableViewCellDidBeginTextEditing:self];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  
  [textField resignFirstResponder];
  return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
  
  return YES && [self.delegate tableViewCellShouldEndTextEditing:self];;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

  self.todoItem.text = textField.text;
  [self.delegate tableViewCellDidEndTextEditing:self];
}

- (BOOL)isUserInteractionEnabled {
  
  self.strikeThroughText.userInteractionEnabled = !self.todoItem.isCompleted;
  
  return super.userInteractionEnabled;
}

@end
