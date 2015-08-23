ASValueTrackingSlider
========

###What is it?


A UISlider subclass that displays live values in an easy to customize popup view.

![screenshot] (http://alskipp.github.io/ASValueTrackingSlider/img/screenshot1.gif)

If you'd like the same functionality for UIProgressView then check out [ASProgressPopupView](https://github.com/alskipp/ASProgressPopupView).

Features
---

* Live updating of UISlider value
* Customizable properties:
  * textColor
  * font
  * popUpViewColor
  * popUpViewAnimatedColors - popUpView and UISlider track color animate as value changes
  * popUpViewCornerRadius
  * popUpViewArrowLength
  
* Set your own NSNumberFormatter to control the displayed values
* Optional dataSource - supply your own custom text to the popUpView label
* Wholesome springy animation


Which files are needed?
---

For [CocoaPods](http://beta.cocoapods.org) users, simply add `pod 'ASValueTrackingSlider'` to your podfile. If you'd like to test the included demo project before including it in your own work, then type `$ pod try ASValueTrackingSlider` in the terminal. CocoaPods will download the demo project into a temp folder and open it in Xcode. Magic.

If you don't use CocoaPods, just include these files in your project:

* ASValueTrackingSlider (.h .m)
* ASValuePopUpView (.h .m)


How to use it
---

It’s very simple. Drag a UISlider into your Storyboard/nib and set its class to ASValueTrackingSlider – that's it.
The examples below demonstrate how to customize the appearance and value displayed.

```objective-c
self.slider.maximumValue = 255.0;
self.slider.popUpViewCornerRadius = 12.0;
[self.slider setMaxFractionDigitsDisplayed:0];
self.slider.popUpViewColor = [UIColor colorWithHue:0.55 saturation:0.8 brightness:0.9 alpha:0.7];
self.slider.font = [UIFont fontWithName:@"GillSans-Bold" size:22];
self.slider.textColor = [UIColor colorWithHue:0.55 saturation:1.0 brightness:0.5 alpha:1];
```

![screenshot] (http://alskipp.github.io/ASValueTrackingSlider/img/screenshot2.png)


```objective-c
NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
[formatter setNumberStyle:NSNumberFormatterPercentStyle];
[self.slider setNumberFormatter:formatter];
self.slider.popUpViewAnimatedColors = @[[UIColor purpleColor], [UIColor redColor], [UIColor orangeColor]];
self.slider.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:26];
```

![screenshot] (http://alskipp.github.io/ASValueTrackingSlider/img/screenshot3.png)

The popUpView adjusts itself so that it doesn't extend beyond the width of the slider control.


###How to use custom strings in popUpView label

Set your controller as the `dataSource` to `ASValueTrackingSlider` and adopt the `ASValueTrackingSliderDataSource`, then return NSStrings for any values you want to customize.
  
```objective-c
// slider has a custom NSNumberFormatter to display temperature in °C
// the dataSource method below returns custom NSStrings for specific values
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
```

![screenshot] (http://alskipp.github.io/ASValueTrackingSlider/img/screenshot4.png)


###How to use with UITableView

To use  effectively inside a UITableView you need to implement the `<ASValueTrackingSliderDelegate>` protocol. If you just embed an ASValueTrackingSlider inside a UITableViewCell the popUpView will probably be obscured by the cell above. The delegate method notifies you before the popUpView appears so that you can ensure that your UITableViewCell is rendered above the others.

The recommended technique for use with UITableView is to create a UITableViewCell subclass that implements the delegate method.


```objective-c
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
```
 
