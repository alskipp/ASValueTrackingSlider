//
//  ASViewController.m
//  ValueTrackingSlider
//
//  Created by Alan Skipp on 19/10/2013.
//  Copyright (c) 2013 Alan Skipp. All rights reserved.
//

#import "ViewController.h"
#import "ASValueTrackingSlider.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider1;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider2;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider3;
@property (weak, nonatomic) IBOutlet ASValueTrackingSlider *slider4;
@end

@implementation ViewController
{
    NSArray *_sliders;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // customize slider 1
    self.slider1.maximumValue = 2.0;

    
    // customize slider 2
    self.slider2.maximumValue = 255.0;
    [self.slider2 setMaxFractionDigitsDisplayed:0];
    self.slider2.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
    self.slider2.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
    self.slider2.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];

    
    // customize slider 3
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterPercentStyle];
    [self.slider3 setNumberFormatter:formatter];
    self.slider3.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
    self.slider3.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];
    
    
    // customize slider 4
    NSNumberFormatter *tempFormatter = [[NSNumberFormatter alloc] init];
    [tempFormatter setPositiveSuffix:@"°C"];
    [tempFormatter setNegativeSuffix:@"°C"];
    
    [self.slider4 setNumberFormatter:tempFormatter];
    self.slider4.minimumValue = -20.0;
    self.slider4.maximumValue = 60.0;
    
    self.slider4.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:26];
    self.slider4.textColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    UIColor *coldBlue = [UIColor colorWithHue:0.6 saturation:0.7 brightness:1.0 alpha:1.0];
    UIColor *blue = [UIColor colorWithHue:0.55 saturation:0.75 brightness:1.0 alpha:1.0];
    UIColor *green = [UIColor colorWithHue:0.3 saturation:0.65 brightness:0.8 alpha:1.0];
    UIColor *yellow = [UIColor colorWithHue:0.15 saturation:0.9 brightness:0.9 alpha:1.0];
    UIColor *red = [UIColor colorWithHue:0.0 saturation:0.8 brightness:1.0 alpha:1.0];

    [self.slider4 setPopUpViewAnimatedColors:@[coldBlue, blue, green, yellow, red]
                               withPositions:@[@-20, @0, @5, @25, @60]];
    
    _sliders = @[_slider1, _slider2, _slider3, _slider4];
}

- (IBAction)toggleShowHide:(UIButton *)sender
{
    sender.selected = !sender.selected;
    for (ASValueTrackingSlider *slider in _sliders) {
        sender.selected ? [slider showPopUpView] : [slider hidePopUpView];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
