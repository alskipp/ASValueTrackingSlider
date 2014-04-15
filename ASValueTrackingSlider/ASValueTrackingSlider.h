//
//  ASValueTrackingSlider.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ASValueTrackingSliderDelegate;

@interface ASValueTrackingSlider : UISlider

// delegate is only needed when used with a TableView or CollectionView - see below
@property (weak, nonatomic) id<ASValueTrackingSliderDelegate> delegate;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIFont *font;

// setting the value of 'popUpViewColor' overrides 'popUpViewAnimatedColors' and vice versa
// the return value of 'popUpViewColor' is the currently displayed value
// this will vary if 'popUpViewAnimatedColors' is set (see below)
@property (strong, nonatomic) UIColor *popUpViewColor;

// pass an array of  2 or more UIColors to animate the color change as the slider moves
@property (strong, nonatomic) NSArray *popUpViewAnimatedColors;

// the above @property distributes the colors evenly across the slider
// to specify the exact position of colors on the slider scale, pass an NSArray of NSNumbers
- (void)setPopUpViewAnimatedColors:(NSArray *)popUpViewAnimatedColors withPositions:(NSArray *)positions;

// changes the left handside of the UISlider track to match current popUpView color
// the track color alpha is always set to 1.0, even if popUpView color is less than 1.0
@property (nonatomic) BOOL autoAdjustTrackColor; // (default is YES)

// when setting max FractionDigits the min value is automatically set to the same value
// this ensures that the PopUpView frame maintains a consistent width
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits;

// take full control of the format dispayed with a custom NSNumberFormatter
- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter;

@end

// when embedding an ASValueTrackingSlider inside a TableView or CollectionView
// you need to ensure that the cell it resides in is brought to the front of the view hierarchy
// to prevent the popUpView from being obscured
@protocol ASValueTrackingSliderDelegate <NSObject>
- (void)sliderWillDisplayPopUpView:(ASValueTrackingSlider *)slider;

@optional
- (void)sliderDidHidePopUpView:(ASValueTrackingSlider *)slider;
@end

/*
// the recommended technique for use with a tableView is to create a UITableViewCell subclass ↓
 
 @interface SliderCell : UITableViewCell <ASValueTrackingSliderDelegate>
 @property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider;
 @end
 
 @implementation SliderCell
 - (void)awakeFromNib
 {
    self.slider.delegate = self;
 }
 
 - (void)sliderWillDisplayPopUpView:(ASValueTrackingSlider *)slider;
 {
    [self.superview bringSubviewToFront:self];
 }
 @end
 */
