//
//  ASValuePopUpView.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 27/03/2014.
//  Copyright (c) 2014 Alan Skipp. All rights reserved.
//

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// This UIView subclass is used internally by ASValueTrackingSlider
// The public API is declared in ASValueTrackingSlider.h
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#import "ASValuePopUpView.h"

const float ARROW_LENGTH = 13.0;
const float MIN_POPUPVIEW_WIDTH = 36.0;
const float MIN_POPUPVIEW_HEIGHT = 27.0;
const float POPUPVIEW_WIDTH_PAD = 1.15;
const float POPUPVIEW_HEIGHT_PAD = 1.1;

NSString *const FillColorAnimation = @"fillColor";

@implementation ASValuePopUpView
{
    NSMutableAttributedString *_attributedString;
    CAShapeLayer *_backgroundLayer;
    CATextLayer *_textLayer;
    CGSize _oldSize;
    CGFloat _arrowCenterOffset;
}

#pragma mark - public

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.anchorPoint = CGPointMake(0.5, 1);
        
        self.userInteractionEnabled = NO;
        _backgroundLayer = [CAShapeLayer layer];
        _backgroundLayer.anchorPoint = CGPointMake(0, 0);
        
        _textLayer = [CATextLayer layer];
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.anchorPoint = CGPointMake(0, 0);
        _textLayer.contentsScale = [UIScreen mainScreen].scale;
        _textLayer.actions = @{@"bounds" : [NSNull null],   // prevent implicit animation of bounds
                               @"position" : [NSNull null]};// and position
        
        [self.layer addSublayer:_backgroundLayer];
        [self.layer addSublayer:_textLayer];
        
        _attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    }
    return self;
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (_cornerRadius == radius) return;
    _cornerRadius = radius;
    [self drawPath];
}

- (UIColor *)color
{
    return [UIColor colorWithCGColor:[_backgroundLayer.presentationLayer fillColor]];
}

- (void)setColor:(UIColor *)color
{
    [_backgroundLayer removeAnimationForKey:FillColorAnimation];
    _backgroundLayer.fillColor = color.CGColor;
}

- (UIColor *)opaqueColor
{
    return opaqueUIColorFromCGColor([_backgroundLayer.presentationLayer fillColor] ?: _backgroundLayer.fillColor);
}

- (void)setTextColor:(UIColor *)color
{
    [_attributedString addAttribute:NSForegroundColorAttributeName
                              value:(id)color.CGColor
                              range:NSMakeRange(0, [_attributedString length])];
}

- (void)setFont:(UIFont *)font
{
    [_attributedString addAttribute:NSFontAttributeName
                              value:font
                              range:NSMakeRange(0, [_attributedString length])];
}

- (void)setString:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    _textLayer.string = _attributedString;
}

// set up an animation, but prevent it from running automatically
// the animation progress will be adjusted manually
- (void)setAnimatedColors:(NSArray *)animatedColors withKeyTimes:(NSArray *)keyTimes
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:FillColorAnimation];
    colorAnim.keyTimes = keyTimes;
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    colorAnim.delegate = self;
    
    // As the interpolated color values from the presentationLayer are needed immediately
    // the animation must be allowed to start to initialize _backgroundLayer's presentationLayer
    // hence the speed is set to min value - then set to zero in 'animationDidStart:' delegate method
    _backgroundLayer.speed = FLT_MIN;
    _backgroundLayer.timeOffset = 0.0;
    
    [_backgroundLayer addAnimation:colorAnim forKey:FillColorAnimation];
}

- (void)setAnimationOffset:(CGFloat)offset
{
    _backgroundLayer.timeOffset = offset;
}

- (void)setArrowCenterOffset:(CGFloat)offset
{
    if (_arrowCenterOffset == offset) return; // only redraw if the offset has changed
    _arrowCenterOffset = offset;
    
    // the arrow tip should be the origin of any scale animations
    // to achieve this, position the anchorPoint at the tip of the arrow
    CGRect f = self.layer.frame;
    self.layer.anchorPoint = CGPointMake(0.5+(offset/self.bounds.size.width), 1);
    self.layer.frame = f; // changing anchor repositions layer, so must reset frame afterwards
    [self drawPath];
}

- (CGSize)popUpSizeForString:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    CGFloat w, h;
    w = ceilf(MAX([_attributedString size].width, MIN_POPUPVIEW_WIDTH) * POPUPVIEW_WIDTH_PAD);
    h = ceilf(MAX([_attributedString size].height, MIN_POPUPVIEW_HEIGHT) * POPUPVIEW_HEIGHT_PAD + ARROW_LENGTH);
    return CGSizeMake(w, h);
}

- (void)show
{
    [CATransaction begin]; {
        // start the transform animation from its current value if it's already running
        NSValue *fromValue = [self.layer animationForKey:@"transform"] ? [self.layer.presentationLayer valueForKey:@"transform"] : [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
        
        CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnim.fromValue = fromValue;
        scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.8 :2.5 :0.35 :0.5]];
        scaleAnim.removedOnCompletion = NO;
        scaleAnim.fillMode = kCAFillModeForwards;
        scaleAnim.duration = 0.4;
        [self.layer addAnimation:scaleAnim forKey:@"transform"];
        
        CABasicAnimation* fadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeInAnim.fromValue = [self.layer.presentationLayer valueForKey:@"opacity"];
        fadeInAnim.duration = 0.1;
        fadeInAnim.toValue = @1.0;
        [self.layer addAnimation:fadeInAnim forKey:@"opacity"];
        
        self.layer.opacity = 1.0;
    } [CATransaction commit];
}

- (void)hide
{
    [CATransaction begin]; {
        [CATransaction setCompletionBlock:^{
            // remove the transform animation if the animation finished and wasn't interrupted
            if (self.layer.opacity == 0.0) [self.layer removeAnimationForKey:@"transform"];
            [self.delegate popUpViewDidHide];
        }];
        
        CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnim.fromValue = [self.layer.presentationLayer valueForKey:@"transform"];
        scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
        scaleAnim.duration = 0.6;
        scaleAnim.removedOnCompletion = NO;
        scaleAnim.fillMode = kCAFillModeForwards;
        [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.1 :-2 :0.3 :3]];
        [self.layer addAnimation:scaleAnim forKey:@"transform"];
        
        CABasicAnimation* fadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOutAnim.fromValue = [self.layer.presentationLayer valueForKey:@"opacity"];
        fadeOutAnim.toValue = @0.0;
        fadeOutAnim.duration = 0.8;
        [self.layer addAnimation:fadeOutAnim forKey:@"opacity"];
        self.layer.opacity = 0.0;
    } [CATransaction commit];
}

#pragma mark - CAAnimation delegate

// set the speed to zero to freeze the animation and set the offset to the correct value
// the animation can now be updated manually by explicity setting its 'timeOffset'
- (void)animationDidStart:(CAAnimation *)animation
{
    _backgroundLayer.speed = 0.0;
    _backgroundLayer.timeOffset = [self.delegate currentValueOffset];
    [self.delegate colorAnimationDidStart];
}

#pragma mark - private

- (void)drawPath
{
    // Create rounded rect
    CGRect roundedRect = self.bounds;
    roundedRect.size.height -= ARROW_LENGTH;
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:_cornerRadius];
    
    // Create arrow path
    CGFloat maxX = CGRectGetMaxX(roundedRect); // prevent arrow from extending beyond this point
    CGFloat arrowTipX = CGRectGetMidX(self.bounds) + _arrowCenterOffset;
    CGPoint tip = CGPointMake(arrowTipX, CGRectGetMaxY(self.bounds));
    
    CGFloat arrowLength = CGRectGetHeight(roundedRect)/2.0;
    CGFloat x = arrowLength * tan(45.0 * M_PI/180); // x = half the length of the base of the arrow
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:tip];
    [arrowPath addLineToPoint:CGPointMake(MAX(arrowTipX - x, 0), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath addLineToPoint:CGPointMake(MIN(arrowTipX + x, maxX), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath closePath];
    
    // combine arrow path and rounded rect
    [roundedRectPath appendPath:arrowPath];
    
    _backgroundLayer.path = roundedRectPath.CGPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (CGSizeEqualToSize(self.bounds.size, _oldSize)) return; // return if view size hasn't changed

    _oldSize = self.bounds.size;
    _backgroundLayer.bounds = self.bounds;
    
    CGFloat textHeight = [_textLayer.string size].height;
    CGRect textRect = CGRectMake(self.bounds.origin.x,
                                 (self.bounds.size.height-ARROW_LENGTH-textHeight)/2,
                                 self.bounds.size.width, textHeight);
    _textLayer.frame = CGRectIntegral(textRect);
    [self drawPath];
}

static UIColor* opaqueUIColorFromCGColor(CGColorRef col)
{
    const CGFloat *components = CGColorGetComponents(col);
    UIColor *color;
    if (CGColorGetNumberOfComponents(col) == 2) {
        color = [UIColor colorWithWhite:components[0] alpha:1.0];
    } else {
        color = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:1.0];
    }
    return color;
}


@end
