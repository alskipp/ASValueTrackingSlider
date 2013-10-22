ValueTrackingSlider
========

What is it?
---

A UISlider Subclass that displays live values in a popUpView. It’s inspired by the implementation found [here](https://github.com/mneuwert/iOS-Custom-Controls), but this version is built using CALayers.
It’s designed for use with iOS7 (though with a few alterations, it should be simple enough to get working on iOS6 and below).

![screenshot] (http://alskipp.github.io/ValueTrackingSlider/img/screenshot1.png)

Features
---

* Live updating of UISlider value
* Customizable properties:
  * textColor
  * font
  * popUpViewColor
* Set your own NSNumberFormatter to control the displayed values
* Wholesome springy animation


What do you need?
---

Just include these two files in your project:

* ASValueTrackingSlider.h
* ASValueTrackingSlider.m

How to use it
---

It’s very simple. Just drag a UISlider into your Storyboard/nib and set it’s class to ASValueTrackingSlider.
The examples below demonstrate how to customize the appearance and value displayed.

```objective-c
self.slider.maximumValue = 255.0;
[self.slider setMaxFractionDigitsDisplayed:0];
self.slider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.5 brightness:0.9 alpha:0.8];
self.slider.textColor = [UIColor colorWithHue:0.55 saturation:1 brightness:0.4 alpha:1];
self.slider.font = [UIFont fontWithName:@"Menlo-Bold" size:22];
```

![screenshot] (http://alskipp.github.io/ValueTrackingSlider/img/screenshot2.png)


```objective-c
NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
[formatter setNumberStyle:NSNumberFormatterPercentStyle];
[self.slider setNumberFormatter:formatter];
self.slider.popUpViewColor = [UIColor colorWithRed:0.1 green:0.7 blue:0.3 alpha:1];
self.slider.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
```

![screenshot] (http://alskipp.github.io/ValueTrackingSlider/img/screenshot3.png)

The popUpView adjusts itself so that it doesn't extend beyond the width of the slider control.