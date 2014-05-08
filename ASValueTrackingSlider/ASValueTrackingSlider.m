//
//  ASValueTrackingSlider.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ASValueTrackingSlider.h"
#import "ASValuePopUpView.h"

static void * ASValueTrackingSliderBoundsContext = &ASValueTrackingSliderBoundsContext;

@interface ASValueTrackingSlider() <ASValuePopUpViewDelegate>
@property (strong, nonatomic) ASValuePopUpView *popUpView;
@property (nonatomic) BOOL popUpViewAlwaysOn; // (default is NO)
@end

@implementation ASValueTrackingSlider
{
    NSNumberFormatter *_numberFormatter;
    CGSize _defaultPopUpViewSize; // size that fits largest string from _numberFormatter
    CGSize _popUpViewSize; // usually == _defaultPopUpViewSize, but can vary if dataSource is used
    UIColor *_popUpViewColor;
    NSArray *_keyTimes;
    CGFloat _valueRange;
}

#pragma mark - initialization

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - public

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
    [self.popUpView setTextColor:color];
}

- (void)setFont:(UIFont *)font
{
    NSAssert(font, @"font can not be nil, it must be a valid UIFont");
    _font = font;
    [self.popUpView setFont:font];

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

- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors
{
    [self setPopUpViewAnimatedColors:popUpViewAnimatedColors withPositions:nil];
}

// if 2 or more colors are present, set animated colors
// if only 1 color is present then call 'setPopUpViewColor:'
// if arg is nil then restore previous _popUpViewColor
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors withPositions:(NSArray *)positions
{
    if (positions) {
        NSAssert([popUpViewAnimatedColors count] == [positions count], @"popUpViewAnimatedColors and locations should contain the same number of items");
    }
    
    _popUpViewAnimatedColors = popUpViewAnimatedColors;
    _keyTimes = [self keyTimesFromSliderPositions:positions];
    
    if ([popUpViewAnimatedColors count] >= 2) {
        [self.popUpView setAnimatedColors:popUpViewAnimatedColors withKeyTimes:_keyTimes];
    } else {
        [self setPopUpViewColor:[popUpViewAnimatedColors lastObject] ?: _popUpViewColor];
    }
}

- (void)setPopUpViewCornerRadius:(CGFloat)popUpViewCornerRadius
{
    _popUpViewCornerRadius = popUpViewCornerRadius;
    [self.popUpView setCornerRadius:popUpViewCornerRadius];
}

// when either the min/max value or number formatter changes, recalculate the popUpView width
- (void)setMaximumValue:(float)maximumValue
{
    [super setMaximumValue:maximumValue];
    _valueRange = self.maximumValue - self.minimumValue;
    [self calculatePopUpViewSize];
}

- (void)setMinimumValue:(float)minimumValue
{
    [super setMinimumValue:minimumValue];
    _valueRange = self.maximumValue - self.minimumValue;
    [self calculatePopUpViewSize];
}

// set max and min digits to same value to keep string length consistent
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits
{
    [_numberFormatter setMaximumFractionDigits:maxDigits];
    [_numberFormatter setMinimumFractionDigits:maxDigits];
    [self calculatePopUpViewSize];
}

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    _numberFormatter = [numberFormatter copy];
    [self calculatePopUpViewSize];
}

- (NSNumberFormatter *)numberFormatter
{
    return [_numberFormatter copy]; // return a copy to prevent formatter properties changing and causing mayhem
}

- (void)showPopUpView
{
    self.popUpViewAlwaysOn = YES;
    [self _showPopUpView];
}

- (void)hidePopUpView
{
    self.popUpViewAlwaysOn = NO;
    [self.popUpView hide];
}

#pragma mark - ASValuePopUpViewDelegate

- (void)colorAnimationDidStart
{
    [self autoColorTrack];
}

- (void)popUpViewDidHide;
{
    if ([self.delegate respondsToSelector:@selector(sliderDidHidePopUpView:)]) {
        [self.delegate sliderDidHidePopUpView:self];
    }
}

// returns the current offset of UISlider value in the range 0.0 – 1.0
- (CGFloat)currentValueOffset
{
    return (self.value + ABS(self.minimumValue)) / _valueRange;
}

#pragma mark - private

- (void)setup
{
    _autoAdjustTrackColor = YES;
    _valueRange = self.maximumValue - self.minimumValue;
    _popUpViewAlwaysOn = NO;

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setRoundingMode:NSNumberFormatterRoundHalfUp];
    [formatter setMaximumFractionDigits:2];
    [formatter setMinimumFractionDigits:2];
    _numberFormatter = formatter;

    self.popUpView = [[ASValuePopUpView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.popUpViewColor = [UIColor colorWithHue:0.6 saturation:0.6 brightness:0.5 alpha:0.8];

    self.popUpViewCornerRadius = 4.0;
    self.popUpView.alpha = 0.0;
    self.popUpView.delegate = self;
    [self addSubview:self.popUpView];

    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:22.0f];
    [self positionAndUpdatePopUpView];
}

// ensure animation restarts if app is closed then becomes active again
- (void)didBecomeActiveNotification:(NSNotification *)note
{
    if (self.popUpViewAnimatedColors) {
        [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
    }
}

- (void)positionAndUpdatePopUpView
{
    NSString *valueString; // ask dataSource for string, if nil get string from _numberFormatter

    if ((valueString = [self.dataSource slider:self stringForValue:self.value])) {
        _popUpViewSize = [self.popUpView popUpSizeForString:valueString];
    } else {
        valueString = [_numberFormatter stringFromNumber:@(self.value)];
        _popUpViewSize = _defaultPopUpViewSize;
    }
    
    [self adjustPopUpViewFrame];
    [self.popUpView setString:valueString];
    [self.popUpView setAnimationOffset:[self currentValueOffset]];
    
    [self autoColorTrack];
}

- (void)adjustPopUpViewFrame
{
    CGRect thumbRect = [self thumbRect];
    CGFloat thumbW = thumbRect.size.width;
    CGFloat thumbH = thumbRect.size.height;
    
    CGRect popUpRect = CGRectInset(thumbRect, (thumbW - _popUpViewSize.width)/2, (thumbH - _popUpViewSize.height)/2);
    popUpRect.origin.y = thumbRect.origin.y - _popUpViewSize.height;
    
    // determine if popUpRect extends beyond the frame of the UISlider
    // if so adjust frame and set the center offset of the PopUpView's arrow
    CGFloat minOffsetX = CGRectGetMinX(popUpRect);
    CGFloat maxOffsetX = CGRectGetMaxX(popUpRect) - self.bounds.size.width;
    
    CGFloat offset = minOffsetX < 0.0 ? minOffsetX : (maxOffsetX > 0.0 ? maxOffsetX : 0.0);
    popUpRect.origin.x -= offset;

    [self.popUpView setArrowCenterOffset:offset];
    self.popUpView.frame = CGRectIntegral(popUpRect);
}

- (void)autoColorTrack
{
    if (_autoAdjustTrackColor == NO || !_popUpViewAnimatedColors) return;

    super.minimumTrackTintColor = [self.popUpView opaqueColor];
}

- (void)calculatePopUpViewSize
{
    // set _popUpViewSize to the maximum size required (negative values need more width than positive values)
    CGSize minValSize = [self.popUpView popUpSizeForString:[_numberFormatter stringFromNumber:@(self.minimumValue)]];
    CGSize maxValSize = [self.popUpView popUpSizeForString:[_numberFormatter stringFromNumber:@(self.maximumValue)]];

    _defaultPopUpViewSize = (minValSize.width >= maxValSize.width) ? minValSize : maxValSize;
    _popUpViewSize = _defaultPopUpViewSize;
}

// takes an array of NSNumbers in the range self.minimumValue - self.maximumValue
// returns an array of NSNumbers in the range 0.0 - 1.0
- (NSArray *)keyTimesFromSliderPositions:(NSArray *)positions
{
    if (!positions) return nil;
    
    NSMutableArray *keyTimes = [NSMutableArray array];
    for (NSNumber *num in [positions sortedArrayUsingSelector:@selector(compare:)]) {
        [keyTimes addObject:@((num.floatValue + ABS(self.minimumValue)) / _valueRange)];
    }
    return keyTimes;
}

- (CGRect)thumbRect
{
    return [self thumbRectForBounds:self.bounds
                          trackRect:[self trackRectForBounds:self.bounds]
                              value:self.value];
}

- (void)_showPopUpView {
    if (self.delegate) {
        [self.delegate sliderWillDisplayPopUpView:self];
    }
    [self positionAndUpdatePopUpView];
    [self.popUpView show];
}

#pragma mark - subclassed

- (void)didMoveToWindow
{
    if (!self.window) { // removed from window - cancel notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self removeObserver:self forKeyPath:@"bounds"];
    }
    else { // added to window - register notifications and observers
        
        if (self.popUpViewAnimatedColors) { // restart color animation if needed
            [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [self addObserver:self forKeyPath:@"bounds"
                  options:NSKeyValueObservingOptionNew
                  context:ASValueTrackingSliderBoundsContext];
    }
}

- (void)setValue:(float)value
{
    [super setValue:value];
    if (self.popUpViewAlwaysOn) [self positionAndUpdatePopUpView];
}

// the behaviour of setValue:animated: is different between iOS6 and iOS7
// wrap iOS6 version in animation block to animate popUpView with slider
- (void)setValue:(float)value animated:(BOOL)animated
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [super setValue:value animated:animated];
        [self positionAndUpdatePopUpView];
    }
    else {
        [UIView animateWithDuration:0.25 animations:^{
            [super setValue:value animated:animated];
            [self positionAndUpdatePopUpView];
        }];
    }
}

- (void)setMinimumTrackTintColor:(UIColor *)color
{
    self.autoAdjustTrackColor = NO; // if a custom value is set then prevent auto coloring
    [super setMinimumTrackTintColor:color];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    if (begin) [self _showPopUpView];
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
    if (self.popUpViewAlwaysOn == NO) [self.popUpView hide];
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    [self positionAndUpdatePopUpView];
    if (self.popUpViewAlwaysOn == NO) [self.popUpView hide];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ASValueTrackingSliderBoundsContext) {
        if (self.popUpViewAlwaysOn) {
            [self positionAndUpdatePopUpView];
            if (self.popUpViewAnimatedColors) {
                [self.popUpView setAnimatedColors:_popUpViewAnimatedColors withKeyTimes:_keyTimes];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
