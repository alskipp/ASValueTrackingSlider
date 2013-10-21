//
//  ASValueTrackingSlider.h
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ASValueTrackingSlider : UISlider
- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter;

// when setting max FractionDigits the min value is automatically set to the same value
// this ensures that the PopView frame maintains a consistent width
- (void)setMaxFractionDigitsDisplayed:(NSUInteger)maxDigits;
@end
