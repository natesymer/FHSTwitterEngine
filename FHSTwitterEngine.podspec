
Pod::Spec.new do |s|
  s.name             = "FHSTwitterEngine"
  s.version	     = "0.1.8.3"
  s.summary          = "Twitter API for Cocoa developers"
 
  s.homepage         = "https://github.com/fhsjaagshs/FHSTwitterEngine"
  s.license          = 'MIT'
  s.author           = { "Nathaniel Symer" => "nate@natesymer.com" }
  s.source           = { :git => "https://github.com/salah-ghanim/FHSTwitterEngine.git", :tag => s.version.to_s }
  s.social_media_url   = "https://twitter.com/natesymer"
  s.platform     = :ios, '5.1'
  s.requires_arc = true

  s.source_files = 'src'

end
