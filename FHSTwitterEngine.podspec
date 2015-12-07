
Pod::Spec.new do |s|
  s.name             = "FHSTwitterEngine"
  s.version	     = "1.8.1"
  s.summary          = "Twitter API for Cocoa developers"
 
  s.homepage         = "https://github.com/fhsjaagshs/FHSTwitterEngine"
  s.license          = 'MIT'
  s.author           = [{ "Nathaniel Symer" => "nate@natesymer.com" }, { "dkhamsing" => "dkhamsing8@gmail.com" }]
  s.source           = { :git => "https://github.com/fhsjaagshs/FHSTwitterEngine.git", :tag => s.version.to_s }
  s.platform     = :ios, '5.1'
  s.requires_arc = true

  s.source_files = 'FHSTwitterEngine/*'
end
