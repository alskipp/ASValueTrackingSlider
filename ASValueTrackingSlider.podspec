Pod::Spec.new do |s|
  s.name             = "ASValueTrackingSlider"
  s.version          = "0.12.1"
  s.summary          = "A UISlider subclass that displays the slider value in an animated popUpView"
  s.description      = <<-DESC
                       Displays continuously updated values in an animated popUpView 
                       * Customize: font, font color, background color, corner radius
                       * Option to animate background color and slider track color as value changes
                       * Optional dataSource protocol to fully customize label text
                       DESC
  s.homepage         = "https://github.com/alskipp/ASValueTrackingSlider"
  s.screenshots      = "http://alskipp.github.io/ASValueTrackingSlider/img/screenshot1.gif",
                       "http://alskipp.github.io/ASValueTrackingSlider/img/screenshot2.png"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { "Al Skipp" => "al_skipp@fastmail.fm" }
  s.social_media_url = 'https://twitter.com/al_skipp'
  
  s.platform         = :ios, '8.0'
  s.source           = { :git => "https://github.com/alskipp/ASValueTrackingSlider.git", :tag => "0.12.1" }
  s.source_files     = 'ASValueTrackingSlider'
  s.requires_arc     = true

end
