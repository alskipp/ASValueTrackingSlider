//
//  ASValueTrackingSlider.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASValueTrackingSlider.h"

#define ARROW_LENGTH 13

@interface ASValuePopUpView : UIView
- (void)setString:(NSAttributedString *)string;
- (UIColor *)popUpViewColor;
- (void)setPopUpViewColor:(UIColor *)color;
- (void)setPopUpViewAnimatedColors:(NSArray *)animatedColors offset:(CGFloat)offset;
- (void)setAnimationOffset:(CGFloat)offset;
@end

@implementation ASValuePopUpView
{
    CAShapeLayer *_backgroundLayer;
    CATextLayer *_textLayer;
    CGSize _oldSize;
    CGFloat _arrowCenterOffset;
}

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
    }
    return self;
}

- (void)setString:(NSAttributedString *)string
{
    _textLayer.string = string;
}

- (UIColor *)popUpViewColor
{
    return [UIColor colorWithCGColor:[_backgroundLayer.presentationLayer fillColor]];
}

- (void)setPopUpViewColor:(UIColor *)color;
{
    [_backgroundLayer removeAnimationForKey:@"fillColor"];
    _backgroundLayer.fillColor = color.CGColor;
}

- (void)setPopUpViewAnimatedColors:(NSArray *)animatedColors offset:(CGFloat)offset;
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:@"fillColor"];
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    [_backgroundLayer addAnimation:colorAnim forKey:@"fillColor"];
    
    _backgroundLayer.speed = 0.0;
    _backgroundLayer.beginTime = offset;
    _backgroundLayer.timeOffset = 0.0;
}

- (void)setAnimationOffset:(CGFloat)offset
{
    _backgroundLayer.timeOffset = offset;
}

- (void)setArrowCenterOffset:(CGFloat)offset
{
    // only redraw if the offset has changed
    if (_arrowCenterOffset != offset) {
        _arrowCenterOffset = offset;
        
        // the arrow tip should be the origin of any scale animations
        // to achieve this, position the anchorPoint at the tip of the arrow
        self.layer.anchorPoint = CGPointMake(0.5+(offset/self.bounds.size.width), 1);
        [self drawPath];
    }
}

- (void)drawPath
{
    // Create rounded rect
    CGRect roundedRect = self.bounds;
    roundedRect.size.height -= ARROW_LENGTH;
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:4.0];
    
    // Create arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    CGFloat arrowX = CGRectGetMidX(self.bounds) + _arrowCenterOffset;
    CGPoint p0 = CGPointMake(arrowX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((arrowX - 6.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((arrowX + 6.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    // combine arrow path and rounded rect
    [roundedRectPath appendPath:arrowPath];

    _backgroundLayer.path = roundedRectPath.CGPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // only redraw if the view size has changed
    if (!CGSizeEqualToSize(self.bounds.size, _oldSize)) {
        _oldSize = self.bounds.size;
        _backgroundLayer.bounds = self.bounds;

        CGFloat textHeight = [_textLayer.string size].height;
        CGRect textRect = CGRectMake(self.bounds.origin.x,
                                     (self.bounds.size.height-ARROW_LENGTH-textHeight)/2,
                                     self.bounds.size.width, textHeight);
        _textLayer.frame = textRect;
        [self drawPath];
    }
}

@end


@interface ASValueTrackingSlider()
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) ASValuePopUpView *popUpView;
@property (readonly, nonatomic) CGRect thumbRect;
@property (strong, nonatomic) NSMutableAttributedString *attributedString;
@end

#define MIN_POPUPVIEW_WIDTH 36.0
#define MIN_POPUPVIEW_HEIGHT 27.0
#define POPUPVIEW_WIDTH_INSET 10.0

@implementation ASValueTrackingSlider
{
    CGFloat _popUpViewWidth;
    CGFloat _popUpViewHeight;
    UIColor *_popUpViewColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - public methods

- (void)setTextColor:(UIColor *)color
{
    _textColor = color;
    [self.attributedString addAttribute:NSForegroundColorAttributeName
                                  value:(id)color.CGColor
                                  range:NSMakeRange(0, [_attributedString length])];
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    [self.attributedString addAttribute:NSFontAttributeName
                                  value:font
                                  range:NSMakeRange(0, [_attributedString length])];
    [self calculatePopUpViewSize];
}

// return the currently displayed color if possible, otherwise return _popUpViewColor
// if animated colors are set, the color will change each time the slider value changes
- (UIColor *)popUpViewColor
{
    return [self.popUpView popUpViewColor] ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)popUpViewColor
{
    _popUpViewColor = popUpViewColor;
    [self.popUpView setPopUpViewColor:popUpViewColor];
}

// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
// otherwise, set animated colors
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors
{
    _popUpViewAnimatedColors = popUpViewAnimatedColors;
    
    if ([popUpViewAnimatedColors count] < 2) {
        [self.popUpView setPopUpViewColor:[popUpViewAnimatedColors lastObject] ?: _popUpViewColor];
    } else {
        [self.popUpView setPopUpViewAnimatedColors:popUpViewAnimatedColors
                                            offset:[self currentValueOffset]];
    }
}

// when either the min/max value or number formatter changes, recalculate the popUpView width
- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    [self calculatePopUpViewSize];
}

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    [self calculatePopUpViewSize];
}

// set max and min digits to same value to keep string length consistent
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits;
{
    [self.numberFormatter setMaximumFractionDigits:maxDigits];
    [self.numberFormatter setMinimumFractionDigits:maxDigits];
    [self calculatePopUpViewSize];
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    _numberFormatter = numberFormatter;
    [self calculatePopUpViewSize];
}

#pragma mark - private methods

- (void)setup
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    self.numberFormatter = formatter;
    [self setMaxFractionDigitsDisplayed:2];
    
    self.popUpView = [[ASValuePopUpView alloc] initWithFrame:CGRectZero];
    self.popUpView.alpha = 0.0;
    [self addSubview:self.popUpView];
    
    self.attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:22.0f];
    self.popUpViewColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    
    [self calculatePopUpViewSize];
}

- (void)showPopUp
{
    [CATransaction begin]; {
        // if the transfrom animation hasn't run yet then set a default fromValue
        NSValue *fromValue = [self.popUpView.layer animationForKey:@"transform"] ?
        [self.popUpView.layer.presentationLayer valueForKey:@"transform"] :
        [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
        
        CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnim.fromValue = fromValue;
        scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.8 :2.5 :0.35 :0.5]];
        scaleAnim.removedOnCompletion = NO;
        scaleAnim.fillMode = kCAFillModeForwards;
        scaleAnim.duration = 0.4;
        [self.popUpView.layer addAnimation:scaleAnim forKey:@"transform"];
        
        CABasicAnimation* fadeInAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeInAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"opacity"];
        fadeInAnim.duration = 0.1;
        fadeInAnim.toValue = @1.0;
        [self.popUpView.layer addAnimation:fadeInAnim forKey:@"opacity"];
        self.popUpView.layer.opacity = 1.0;
        
    } [CATransaction commit];
}

- (void)hidePopUp
{
    [CATransaction begin]; {
        CABasicAnimation *scaleAnim = [CABasicAnimation animationWithKeyPath:@"transform"];
        scaleAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"transform"];
        scaleAnim.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.5, 0.5, 1)];
        scaleAnim.duration = 0.6;
        scaleAnim.removedOnCompletion = NO;
        scaleAnim.fillMode = kCAFillModeForwards;
        [scaleAnim setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.1 :-2 :0.3 :3]];
        [self.popUpView.layer addAnimation:scaleAnim forKey:@"transform"];
        
        CABasicAnimation* fadeOutAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOutAnim.fromValue = [self.popUpView.layer.presentationLayer valueForKey:@"opacity"];
        fadeOutAnim.toValue = @0.0;
        fadeOutAnim.duration = 0.8;
        [self.popUpView.layer addAnimation:fadeOutAnim forKey:@"opacity"];
        self.popUpView.layer.opacity = 0.0;
    } [CATransaction commit];
}

- (void)positionAndUpdatePopUpView
{
    CGRect thumbRect = self.thumbRect;
    CGFloat thumbW = thumbRect.size.width;
    CGFloat thumbH = thumbRect.size.height;

    CGRect popUpRect = CGRectInset(thumbRect, (thumbW - _popUpViewWidth)/2, (thumbH -_popUpViewHeight)/2);
    popUpRect.origin.y = thumbRect.origin.y - _popUpViewHeight;
    
    // determine if popUpRect extends beyond the frame of the UISlider
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - self.bounds.size.width;
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;
    [self.popUpView setArrowCenterOffset:offset];

    self.popUpView.frame = popUpRect;
    
    NSString *string = [_numberFormatter stringFromNumber:@(self.value)];
    [[self.attributedString mutableString] setString:string];
    [self.popUpView setString:self.attributedString];
    
    [self.popUpView setAnimationOffset:[self currentValueOffset]];
}

- (void)calculatePopUpViewSize
{
    // if the abs of minimumValue is the same or larger than maximumValue, use it to calculate size
    CGFloat value = ABS(self.minimumValue) >= self.maximumValue ? self.minimumValue : self.maximumValue;
    NSString *string = [_numberFormatter stringFromNumber:@(value)];
    [[self.attributedString mutableString] setString:string];
    _popUpViewWidth = ceilf(MAX([self.attributedString size].width, MIN_POPUPVIEW_WIDTH)+POPUPVIEW_WIDTH_INSET);
    _popUpViewHeight = ceilf(MAX([self.attributedString size].height, MIN_POPUPVIEW_HEIGHT)+ARROW_LENGTH);
    
    [self positionAndUpdatePopUpView];
}

- (CGRect)thumbRect
{
    return [self thumbRectForBounds:self.bounds
                          trackRect:[self trackRectForBounds:self.bounds]
                              value:self.value];
}

// returns the current offset of UISlider value in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    CGFloat valueRange = self.maximumValue - self.minimumValue;
    return (self.value + ABS(self.minimumValue)) / valueRange;
}

#pragma mark - subclassed methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin) {
        [self positionAndUpdatePopUpView];
        [self showPopUp];
    }
    return begin;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL continueTrack = [super continueTrackingWithTouch:touch withEvent:event];
    if (continueTrack) [self positionAndUpdatePopUpView];
    return continueTrack;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [super cancelTrackingWithEvent:event];
    [self hidePopUp];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    [self positionAndUpdatePopUpView];
    [self hidePopUp];
}

@end
