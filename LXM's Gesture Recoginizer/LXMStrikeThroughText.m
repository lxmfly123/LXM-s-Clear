//
//  StrikeThroughText.m
//  LXM's Gesture Recoginizer
//
//  Created by FLY.lxm on 4/22/16.
//  Copyright © 2016 FLY.lxm. All rights reserved.
//

#import "LXMStrikeThroughText.h"
#import "LXMTodoItem.h"
#import "LXMTableViewState.h"
#import "LXMTableViewCell.h"
#import "LXMGlobalSettings.h"

static const CGFloat kStrikeThroughThickness = 1.0f;

@interface LXMStrikeThroughText ()

@property (nonatomic, weak) LXMGlobalSettings *globalSettings;

@property (nonatomic, strong) CALayer *strikeThroughLine;
@property (nonatomic, assign) CGColorRef strikeThroughColor;

@end

@implementation LXMStrikeThroughText

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame {
  
  self = [super initWithFrame:frame];
  if (self) {
    self.font = [UIFont systemFontOfSize:18];
    self.returnKeyType = UIReturnKeyDone;
    self.globalSettings = [LXMGlobalSettings sharedInstance];
  }
  return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
  [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  
  [super touchesBegan:touches withEvent:event];
}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//  
//  
//  NSLog(@"hittest");
//  
//  return [super hitTest:point withEvent:event];
//}

- (CALayer *)strikeThroughLine {
  
  if (!_strikeThroughLine) {
    _strikeThroughLine = [CALayer new];
    _strikeThroughLine.frame = CGRectNull;
    _strikeThroughLine.backgroundColor = self.strikeThroughColor;
    _strikeThroughLine.hidden = YES;
    [self.layer addSublayer:_strikeThroughLine];
  }

  return _strikeThroughLine;
}

- (void)layoutSubviews {
  
  [super layoutSubviews];
  [self layoutStrikeThroughLine];
}

- (CGFloat)strikeThroughLength {
  
  CGFloat length = [self.text sizeWithAttributes:@{NSFontAttributeName:self.font}].width + 2 * self.globalSettings.textFieldLeftPadding;
  
  switch (self.parentCell.editingState) {
    case LXMTableViewCellEditingStateNone:
    case LXMTableViewCellEditingStateWillDelete:
    case LXMTableViewCellEditingStateWillCheck:
      break;
      
    case LXMTableViewCellEditingStateNormal:
      if (self.parentCell.actualContentView.frame.origin.x >= 0) {
        if (self.parentCell.todoItem.isCompleted) {
          length = length * (1 - MIN(ABS(self.parentCell.actualContentView.frame.origin.x) / [LXMGlobalSettings sharedInstance].editCommitTriggerWidth, 1.0f));
        } else {
          length = length * (MIN(ABS(self.parentCell.actualContentView.frame.origin.x) / [LXMGlobalSettings sharedInstance].editCommitTriggerWidth, 1.0f));
        }
      }
      break;
  }

  return length;
}

- (CGColorRef)strikeThroughColor {
  
  if (self.parentCell.todoItem.isCompleted) {
    return [UIColor grayColor].CGColor;
  } else {
    return [UIColor whiteColor].CGColor;
  }
}

- (void)layoutStrikeThroughLine {
  
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  self.strikeThroughLine.frame = CGRectMake(0,
                                            self.bounds.size.height / 2, 
                                            [self strikeThroughLength], 
                                            kStrikeThroughThickness);
  
  self.strikeThroughLine.backgroundColor = [self strikeThroughColor];
  
  switch (self.parentCell.editingState) {
    case LXMTableViewCellEditingStateNone:
    case LXMTableViewCellEditingStateWillDelete:
      self.strikeThroughLine.hidden = !self.parentCell.todoItem.isCompleted;
      break;
      
    case LXMTableViewCellEditingStateNormal:
      self.strikeThroughLine.hidden = NO;
      if (!self.parentCell.todoItem.isCompleted && self.parentCell.actualContentView.frame.origin.x < 0) {
        self.strikeThroughLine.hidden = YES;
      }
      break;
      
    case LXMTableViewCellEditingStateWillCheck:

      self.strikeThroughLine.hidden = self.parentCell.todoItem.isCompleted;
      break;
  }
  [CATransaction commit];
}

- (CGRect)textRectForBounds:(CGRect)bounds {
  
  return CGRectMake(self.globalSettings.textFieldLeftPadding, bounds.origin.y, bounds.size.width, bounds.size.height);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  
  return [self textRectForBounds:bounds];
}

@end
