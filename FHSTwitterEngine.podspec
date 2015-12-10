
Pod::Spec.new do |s|
  s.name             = "FHSTwitterEngine"
  s.version	     = "2.0.2"
  s.summary          = "Twitter API for Cocoa developers"
 
  s.homepage         = "https://github.com/fhsjaagshs/FHSTwitterEngine"
  s.license          = 'MIT'
  s.author           = [{ "Nathaniel Symer" => "nate@natesymer.com" }, { "dkhamsing" => "dkhamsing8@gmail.com" }]
  s.social_media_url = 'https://twitter.com/dkhamsing'

  s.source           = { :git => "https://github.com/fhsjaagshs/FHSTwitterEngine.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  
  s.requires_arc = true
  s.source_files = 'FHSTwitterEngine/*'
end
