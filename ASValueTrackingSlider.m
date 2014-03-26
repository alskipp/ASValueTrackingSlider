//
//  ASValueTrackingSlider.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASValueTrackingSlider.h"

#define ARROW_LENGTH 13
NSString *const AnimationLayer = @"animationLayer";
NSString *const FillColorAnimation = @"fillColor";

@interface ASValuePopUpView : UIView

@property (weak, nonatomic) id delegate;

- (UIColor *)color;
- (UIColor *)opaqueColor;
- (void)setColor:(UIColor *)color;
- (void)setAnimatedColors:(NSArray *)animatedColors;
- (void)setString:(NSAttributedString *)string;
- (void)setAnimationOffset:(CGFloat)offset;
- (void)show;
- (void)hide;

@end

@implementation ASValuePopUpView
{
    CAShapeLayer *_backgroundLayer;
    CATextLayer *_textLayer;
    CGSize _oldSize;
    CGFloat _arrowCenterOffset;
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

- (UIColor *)color
{
    return [UIColor colorWithCGColor:[_backgroundLayer.presentationLayer fillColor]];
}

- (UIColor *)opaqueColor
{
    return opaqueUIColorFromCGColor([_backgroundLayer.presentationLayer fillColor] ?: _backgroundLayer.fillColor);
}

- (void)setColor:(UIColor *)color;
{
    [_backgroundLayer removeAnimationForKey:FillColorAnimation];
    _backgroundLayer.fillColor = color.CGColor;
}

// set up an animation with a speed of zero to prevent it from running
// the animation offset can then be controlled by the UISlider
- (void)setAnimatedColors:(NSArray *)animatedColors
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:FillColorAnimation];
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    colorAnim.delegate = self.delegate; // delegate will be used to set speed to zero in 'animationDidStart:'
    
    // the delegate uses this key to retrieve the _backgroundLayer
    [colorAnim setValue:_backgroundLayer forKey:AnimationLayer];
    
    // the animation must be allowed to start to initialize the CALayer's presentationLayer
    // because the initial color of 'minimumTrackTintColor' is derived from the presentationLayer
    // hence the speed is set to min value - then set to zero in 'animationDidStart:'
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
    // only redraw if the offset has changed
    if (_arrowCenterOffset != offset) {
        _arrowCenterOffset = offset;
        
        // the arrow tip should be the origin of any scale animations
        // to achieve this, position the anchorPoint at the tip of the arrow
        self.layer.anchorPoint = CGPointMake(0.5+(offset/self.bounds.size.width), 1);
        [self drawPath];
    }
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

#pragma mark - initialization

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

#pragma mark - delegate methods

// this delegate method is received from ASValuePopUpView's background layer
// it is the layer responsible for animating the color change of ASValuePopUpView
// set the speed to zero to freeze the animation and set the offset to the correct value
// the animation will then update only when the slider value changes
- (void)animationDidStart:(CAAnimation *)animation
{
    CALayer *layer = [animation valueForKey:AnimationLayer];
    layer.speed = 0.0;
    layer.timeOffset = [self currentValueOffset];
    [self autoColorTrack];
}

#pragma mark - public methods

- (void)setAutoAdjustTrackColor:(BOOL)autoAdjust
{
    if (_autoAdjustTrackColor == autoAdjust) return;
    
    _autoAdjustTrackColor = autoAdjust;
    
    // setMinimumTrackTintColor has been overridden to also set autoAdjustTrackColor to NO
    // therefore super's implementation must be called to set minimumTrackTintColor
    if (autoAdjust == NO) {
        super.minimumTrackTintColor = nil; // sets track to default blue color
    } else {
        super.minimumTrackTintColor = [self.popUpView opaqueColor];
    }
}

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
    return [self.popUpView color] ?: _popUpViewColor;
}

- (void)setPopUpViewColor:(UIColor *)popUpViewColor
{
    _popUpViewColor = popUpViewColor;
    _popUpViewAnimatedColors = nil; // animated colors should be discarded
    [self.popUpView setColor:popUpViewColor];

    if (_autoAdjustTrackColor) {
        super.minimumTrackTintColor = [self.popUpView opaqueColor];
    }
}

// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
// otherwise, set animated colors
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors
{
    _popUpViewAnimatedColors = popUpViewAnimatedColors;
    
    if ([popUpViewAnimatedColors count] >= 2) {
        [self.popUpView setAnimatedColors:popUpViewAnimatedColors];
        [self autoColorTrack];
    } else {
        [self setPopUpViewColor:[popUpViewAnimatedColors lastObject] ?: _popUpViewColor];
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
    _autoAdjustTrackColor = YES;
    
    // ensure animation restarts if app is closed then becomes active again
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (_popUpViewAnimatedColors) {
                                                          [self.popUpView setAnimatedColors:_popUpViewAnimatedColors];
                                                      }
                                                  }];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:2];
    [formatter setMinimumFractionDigits:2];
    _numberFormatter = formatter;

    self.popUpView = [[ASValuePopUpView alloc] initWithFrame:CGRectZero];
    self.popUpViewColor = [UIColor colorWithHue:0.6 saturation:0.6 brightness:0.5 alpha:0.65];

    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

    self.attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:22.0f];
}

- (void)positionAndUpdatePopUpView
{
    CGRect thumbRect = [self thumbRect];
    CGFloat thumbW = thumbRect.size.width;
    CGFloat thumbH = thumbRect.size.height;

    CGRect popUpRect = CGRectInset(thumbRect, (thumbW - _popUpViewWidth)/2, (thumbH - _popUpViewHeight)/2);
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
    
    [self autoColorTrack];
}

- (void)autoColorTrack
{
    if (_autoAdjustTrackColor == NO || !_popUpViewAnimatedColors) return;

    super.minimumTrackTintColor = [self.popUpView opaqueColor];
}

- (void)calculatePopUpViewSize
{
    // if the abs of minimumValue is the same or larger than maximumValue, use it to calculate size
    CGFloat value = ABS(self.minimumValue) >= self.maximumValue ? self.minimumValue : self.maximumValue;
    NSString *string = [_numberFormatter stringFromNumber:@(value)];
    [[self.attributedString mutableString] setString:string];
    _popUpViewWidth = ceilf(MAX([self.attributedString size].width, MIN_POPUPVIEW_WIDTH)+POPUPVIEW_WIDTH_INSET);
    _popUpViewHeight = ceilf(MAX([self.attributedString size].height, MIN_POPUPVIEW_HEIGHT)+ARROW_LENGTH);
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

- (void)setMinimumTrackTintColor:(UIColor *)color
{
    self.autoAdjustTrackColor = NO; // if a custom value is set then prevent auto coloring
    [super setMinimumTrackTintColor:color];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin) {
        [self positionAndUpdatePopUpView];
        [self.popUpView show];
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
    [self.popUpView hide];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    [self positionAndUpdatePopUpView];
    [self.popUpView hide];
}

@end
