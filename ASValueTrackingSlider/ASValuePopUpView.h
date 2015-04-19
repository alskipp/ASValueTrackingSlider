//
//  ASValuePopUpView.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 27/03/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This UIView subclass is used internally by ASValueTrackingSlider
// The public API is declared in ASValueTrackingSlider.h
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import <UIKit/UIKit.h>

@protocol ASValuePopUpViewDelegate <NSObject>
- (CGFloat)currentValueOffset; //expects value in the range 0.0 - 1.0
- (void)colorDidUpdate:(UIColor *)opaqueColor;
@end

@interface ASValuePopUpView : UIView

@property (weak, nonatomic) id <ASValuePopUpViewDelegate> delegate;
@property (nonatomic) CGFloat cornerRadius;
@property (nonatomic) CGFloat arrowLength;
@property (nonatomic) CGFloat widthPaddingFactor;
@property (nonatomic) CGFloat heightPaddingFactor;

- (UIColor *)color;
- (void)setColor:(UIColor *)color;
- (UIColor *)opaqueColor;

- (void)setTextColor:(UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (void)setText:(NSString *)text;

- (void)setAnimatedColors:(NSArray *)animatedColors withKeyTimes:(NSArray *)keyTimes;

- (void)setAnimationOffset:(CGFloat)animOffset returnColor:(void (^)(UIColor *opaqueReturnColor))block;

- (void)setFrame:(CGRect)frame arrowOffset:(CGFloat)arrowOffset text:(NSString *)text;

- (void)animateBlock:(void (^)(CFTimeInterval duration))block;

- (CGSize)popUpSizeForString:(NSString *)string;

- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated completionBlock:(void (^)())block;

@end