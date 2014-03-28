//
//  ASValuePopUpView.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 27/03/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>

NSString *const AnimationLayer;

@interface ASValuePopUpView : UIView

@property (weak, nonatomic) id delegate;

- (UIColor *)color;
- (UIColor *)opaqueColor;
- (void)setColor:(UIColor *)color;
- (void)setAnimatedColors:(NSArray *)animatedColors;
- (void)setString:(NSString *)string;
- (void)setTextColor:(UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (CGSize)sizeForString:(NSString *)string;
- (void)setAnimationOffset:(CGFloat)offset;
- (void)setArrowCenterOffset:(CGFloat)offset;
- (void)show;
- (void)hide;

@end