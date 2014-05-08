//
//  ASViewController.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ViewController.h"
#import "ASValueTrackingSlider.h"

@interface ViewController () <ASValueTrackingSliderDataSource>
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider1;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider2;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider3;

@property (weak, nonatomic) IBOutlet UISwitch *animateSwitch;
@end

@implementation ViewController
{
    NSArray *_sliders;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize slider 1
    self.slider1.maximumValue = 255.0;
    self.slider1.popUpViewCornerRadius = 0.0;
    [self.slider1 setMaxFractionDigitsDisplayed:0];
    self.slider1.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    self.slider1.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
    self.slider1.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];

    
    // customize slider 2
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.slider2 setNumberFormatter:formatter];
    self.slider2.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.slider2.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];
    
    
    // customize slider 3
    NSNumberFormatter *tempFormatter = [[NSNumberFormatter alloc] init];
    [tempFormatter setPositiveSuffix:@"°C"];
    [tempFormatter setNegativeSuffix:@"°C"];
    
    self.slider3.dataSource = self;
    [self.slider3 setNumberFormatter:tempFormatter];
    self.slider3.minimumValue = -20.0;
    self.slider3.maximumValue = 60.0;
    self.slider3.popUpViewCornerRadius = 16.0;

    self.slider3.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:26];
    self.slider3.textColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    UIColor *coldBlue = [UIColor colorWithHue:0.6 saturation:0.7 brightness:1.0 alpha:1.0];
    UIColor *blue = [UIColor colorWithHue:0.55 saturation:0.75 brightness:1.0 alpha:1.0];
    UIColor *green = [UIColor colorWithHue:0.3 saturation:0.65 brightness:0.8 alpha:1.0];
    UIColor *yellow = [UIColor colorWithHue:0.15 saturation:0.9 brightness:0.9 alpha:1.0];
    UIColor *red = [UIColor colorWithHue:0.0 saturation:0.8 brightness:1.0 alpha:1.0];

    [self.slider3 setPopUpViewAnimatedColors:@[coldBlue, blue, green, yellow, red]
                               withPositions:@[@-20, @0, @5, @25, @60]];
    
    _sliders = @[_slider1, _slider2, _slider3];
}

#pragma mark - ASValueTrackingSliderDataSource

- (NSString *)slider:(ASValueTrackingSlider *)slider stringForValue:(float)value;
{
    value = roundf(value);
    NSString *s;
    if (value < -10.0) {
        s = @"❄️Brrr!⛄️";
    } else if (value > 29.0 && value < 50.0) {
        s = [NSString stringWithFormat:@"😎 %@ 😎", [slider.numberFormatter stringFromNumber:@(value)]];
    } else if (value >= 50.0) {
        s = @"I’m Melting!";
    }
    return s;
}

#pragma mark - IBActions

- (IBAction)toggleShowHide:(UIButton *)sender
{
    sender.selected = !sender.selected;
    for (ASValueTrackingSlider *slider in _sliders) {
        sender.selected ? [slider showPopUpView] : [slider hidePopUpView];
    }
}

- (IBAction)moveSlidersToMinimum:(UIButton *)sender
{
    for (ASValueTrackingSlider *slider in _sliders) {
        if (self.animateSwitch.on) {
            [self animateSlider:slider toValue:slider.minimumValue];
        }
        else {
            slider.value = slider.minimumValue;
        }
    }
}

- (IBAction)moveSlidersToMaximum:(UIButton *)sender
{
    for (ASValueTrackingSlider *slider in _sliders) {
        if (self.animateSwitch.on) {
            [self animateSlider:slider toValue:slider.maximumValue];
        }
        else {
            slider.value = slider.maximumValue;
        }
    }
}

// the behaviour of setValue:animated: is different between iOS6 and iOS7
// need to use animation block on iOS7
- (void)animateSlider:(ASValueTrackingSlider*)slider toValue:(float)value
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        [UIView animateWithDuration:0.5 animations:^{
            [slider setValue:value animated:YES];
        }];
    }
    else {
        [slider setValue:value animated:YES];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
