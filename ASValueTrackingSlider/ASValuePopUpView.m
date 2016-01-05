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

@implementation CALayer (ASAnimationAdditions)

- (void)animateKey:(NSString *)animationName fromValue:(id)fromValue toValue:(id)toValue
         customize:(void (^)(CABasicAnimation *animation))block
{
    [self setValue:toValue forKey:animationName];
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:animationName];
    anim.fromValue = fromValue ?: [self.presentationLayer valueForKey:animationName];
    anim.toValue = toValue;
    if (block) block(anim);
    [self addAnimation:anim forKey:animationName];
}
@end

NSString *const SliderFillColorAnim = @"fillColor";

@implementation ASValuePopUpView
{
    BOOL _shouldAnimate;
    CFTimeInterval _animDuration;
    
    NSMutableAttributedString *_attributedString;
    CAShapeLayer *_pathLayer;
    
    CATextLayer *_textLayer;
    CGFloat _arrowCenterOffset;
    
    // never actually visible, its purpose is to interpolate color values for the popUpView color animation
    // using shape layer because it has a 'fillColor' property which is consistent with _backgroundLayer
    CAShapeLayer *_colorAnimLayer;
}

+ (Class)layerClass {
    return [CAShapeLayer class];
}


#pragma mark - public

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shouldAnimate = NO;
        self.layer.anchorPoint = CGPointMake(0.5, 1);
        
        self.userInteractionEnabled = NO;
        _pathLayer = (CAShapeLayer *)self.layer; // ivar can now be accessed without casting to CAShapeLayer every time
        
        _cornerRadius = 4.0;
        _arrowLength = 13.0;
        _widthPaddingFactor = 1.15;
        _heightPaddingFactor = 1.1;
        
        _textLayer = [CATextLayer layer];
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.anchorPoint = CGPointMake(0, 0);
        _textLayer.contentsScale = [UIScreen mainScreen].scale;
        _textLayer.actions = @{@"contents" : [NSNull null]};
        
        _colorAnimLayer = [CAShapeLayer layer];
        
        [self.layer addSublayer:_colorAnimLayer];
        [self.layer addSublayer:_textLayer];
        
        _attributedString = [[NSMutableAttributedString alloc] initWithString:@" " attributes:nil];
    }
    return self;
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (_cornerRadius == radius) return;
    _cornerRadius = radius;
    _pathLayer.path = [self pathForRect:self.bounds withArrowOffset:_arrowCenterOffset].CGPath;
}

- (UIColor *)color
{
    return [UIColor colorWithCGColor:[_pathLayer.presentationLayer fillColor]];
}

- (void)setColor:(UIColor *)color
{
    _pathLayer.fillColor = color.CGColor;
    [_colorAnimLayer removeAnimationForKey:SliderFillColorAnim]; // single color, no animation required
}

- (UIColor *)opaqueColor
{
    return opaqueUIColorFromCGColor([_colorAnimLayer.presentationLayer fillColor] ?: _pathLayer.fillColor);
}

- (void)setTextColor:(UIColor *)color
{
    _textLayer.foregroundColor = color.CGColor;
}

- (void)setFont:(UIFont *)font
{
    [_attributedString addAttribute:NSFontAttributeName
                              value:font
                              range:NSMakeRange(0, [_attributedString length])];
    
    _textLayer.font = (__bridge CFTypeRef)(font.fontName);
    _textLayer.fontSize = font.pointSize;
}

- (void)setText:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    _textLayer.string = string;
}

// set up an animation, but prevent it from running automatically
// the animation progress will be adjusted manually
- (void)setAnimatedColors:(NSArray *)animatedColors withKeyTimes:(NSArray *)keyTimes
{
    NSMutableArray *cgColors = [NSMutableArray array];
    for (UIColor *col in animatedColors) {
        [cgColors addObject:(id)col.CGColor];
    }
    
    CAKeyframeAnimation *colorAnim = [CAKeyframeAnimation animationWithKeyPath:SliderFillColorAnim];
    colorAnim.keyTimes = keyTimes;
    colorAnim.values = cgColors;
    colorAnim.fillMode = kCAFillModeBoth;
    colorAnim.duration = 1.0;
    colorAnim.delegate = self;
    
    // As the interpolated color values from the presentationLayer are needed immediately
    // the animation must be allowed to start to initialize _colorAnimLayer's presentationLayer
    // hence the speed is set to min value - then set to zero in 'animationDidStart:' delegate method
    _colorAnimLayer.speed = FLT_MIN;
    _colorAnimLayer.timeOffset = 0.0;
    
    [_colorAnimLayer addAnimation:colorAnim forKey:SliderFillColorAnim];
}

- (void)setAnimationOffset:(CGFloat)animOffset returnColor:(void (^)(UIColor *opaqueReturnColor))block
{
    if ([_colorAnimLayer animationForKey:SliderFillColorAnim]) {
        _colorAnimLayer.timeOffset = animOffset;
        _pathLayer.fillColor = [_colorAnimLayer.presentationLayer fillColor];
        block([self opaqueColor]);
    }
}

- (void)setFrame:(CGRect)frame arrowOffset:(CGFloat)arrowOffset text:(NSString *)text
{
    // only redraw path if either the arrowOffset or popUpView size has changed
    if (arrowOffset != _arrowCenterOffset || !CGSizeEqualToSize(frame.size, self.frame.size)) {
        _pathLayer.path = [self pathForRect:frame withArrowOffset:arrowOffset].CGPath;
    }
    _arrowCenterOffset = arrowOffset;
    
    CGFloat anchorX = 0.5+(arrowOffset/CGRectGetWidth(frame));
    self.layer.anchorPoint = CGPointMake(anchorX, 1);
    self.layer.position = CGPointMake(CGRectGetMinX(frame) + CGRectGetWidth(frame)*anchorX, 0);
    self.layer.bounds = (CGRect){CGPointZero, frame.size};
    
    [self setText:text];
}

// _shouldAnimate = YES; causes 'actionForLayer:' to return an animation for layer property changes
// call the supplied block, then set _shouldAnimate back to NO
- (void)animateBlock:(void (^)(CFTimeInterval duration))block
{
    _shouldAnimate = YES;
    _animDuration = 0.5;
    
    CAAnimation *anim = [self.layer animationForKey:@"position"];
    if ((anim)) { // if previous animation hasn't finished reduce the time of new animation
        CFTimeInterval elapsedTime = MIN(CACurrentMediaTime() - anim.beginTime, anim.duration);
        _animDuration = _animDuration * elapsedTime / anim.duration;
    }
    
    block(_animDuration);
    _shouldAnimate = NO;
}

- (CGSize)popUpSizeForString:(NSString *)string
{
    [[_attributedString mutableString] setString:string];
    CGFloat w, h;
    w = ceilf([_attributedString size].width * _widthPaddingFactor);
    h = ceilf(([_attributedString size].height * _heightPaddingFactor) + _arrowLength);
    return CGSizeMake(w, h);
}

- (void)showWithAnimation:(ASValuePopUpViewPresentationAnimationType)animationType
{
    void(^fadeAnimation)() = ^{ self.alpha = 1.0; };
    void (^expandAnimation)() = ^{ self.transform = CGAffineTransformIdentity; };

    switch (animationType) {
        case ASValuePopUpViewPresentationAnimationTypeBounce:
            self.transform = CGAffineTransformMakeScale(0.5, 0.5);
            [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:0 animations:expandAnimation completion:nil];
            // Don't break here because we'll fall through to run the fade along with the bounce

        case ASValuePopUpViewPresentationAnimationTypeFade:
            [UIView animateWithDuration:0.4 animations:fadeAnimation];
            break;

        case ASValuePopUpViewPresentationAnimationTypeNone:
        default:
            fadeAnimation();
            expandAnimation();
            break;
    }
}

- (void)hideWithanimation:(ASValuePopUpViewPresentationAnimationType)animationType completionBlock:(void (^)())block
{
    void(^fadeAnimation)() = ^{ self.alpha = 0.0; };
    void (^shrinkAnimation)() = ^{ self.transform = CGAffineTransformMakeScale(0.2, 0.2); };
    void (^shrinkCompletion)(BOOL) = ^(BOOL finished) {
        self.transform = CGAffineTransformIdentity;
        if (block) {
            block();
        }
    };

    switch (animationType) {
        case ASValuePopUpViewPresentationAnimationTypeBounce:
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:-5 options:0 animations:shrinkAnimation completion:shrinkCompletion];
            [UIView animateWithDuration:0.3 animations:fadeAnimation];
            break;

        case ASValuePopUpViewPresentationAnimationTypeFade:
            [UIView animateWithDuration:0.3 animations:fadeAnimation completion:shrinkCompletion];
            break;

        case ASValuePopUpViewPresentationAnimationTypeNone:
        default:
            fadeAnimation();
            shrinkAnimation();
            shrinkCompletion(YES);
            break;
    }
}

#pragma mark - CAAnimation delegate

// set the speed to zero to freeze the animation and set the offset to the correct value
// the animation can now be updated manually by explicity setting its 'timeOffset'
- (void)animationDidStart:(CAAnimation *)animation
{
    _colorAnimLayer.speed = 0.0;
    _colorAnimLayer.timeOffset = [self.delegate currentValueOffset];
    
    _pathLayer.fillColor = [_colorAnimLayer.presentationLayer fillColor];
    [self.delegate colorDidUpdate:[self opaqueColor]];
}

#pragma mark - private

- (UIBezierPath *)pathForRect:(CGRect)rect withArrowOffset:(CGFloat)arrowOffset;
{
    if (CGRectEqualToRect(rect, CGRectZero)) return nil;
    
    rect = (CGRect){CGPointZero, rect.size}; // ensure origin is CGPointZero
    
    // Create rounded rect
    CGRect roundedRect = rect;
    roundedRect.size.height -= _arrowLength;
    UIBezierPath *popUpPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:_cornerRadius];
    
    // Create arrow path
    CGFloat maxX = CGRectGetMaxX(roundedRect); // prevent arrow from extending beyond this point
    CGFloat arrowTipX = CGRectGetMidX(rect) + arrowOffset;
    CGPoint tip = CGPointMake(arrowTipX, CGRectGetMaxY(rect));
    
    CGFloat arrowLength = CGRectGetHeight(roundedRect)/2.0;
    CGFloat x = arrowLength * tan(45.0 * M_PI/180); // x = half the length of the base of the arrow
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:tip];
    [arrowPath addLineToPoint:CGPointMake(MAX(arrowTipX - x, 0), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath addLineToPoint:CGPointMake(MIN(arrowTipX + x, maxX), CGRectGetMaxY(roundedRect) - arrowLength)];
    [arrowPath closePath];
    
    [popUpPath appendPath:arrowPath];
    
    return popUpPath;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat textHeight = [_attributedString size].height;
    CGRect textRect = CGRectMake(self.bounds.origin.x,
                                 (self.bounds.size.height-_arrowLength-textHeight)/2,
                                 self.bounds.size.width, textHeight);
    _textLayer.frame = CGRectIntegral(textRect);
}

static UIColor* opaqueUIColorFromCGColor(CGColorRef col)
{
    if (col == NULL) return nil;
    
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
