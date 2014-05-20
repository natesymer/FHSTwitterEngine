Pod::Spec.new do |s|
	s.name = "FHSTwitterEngine"
	s.version = "2.0"
	s.summary = "Twitter API for Cocoa developers"
	s.homepage = "https://github.com/fhsjaagshs/FHSTwitterEngine"
	
	s.license = { :type => "MIT", :file => "LICENSE" }
	s.author = { "Nathaniel Symer" => "nate@natesymer.com", "Daniel Khamsing" => "dkhamsing8@gmail.com" }
	s.source = {
		:git => "https://github.com/fhsjaagshs/FHSTwitterEngine.git",
		:tag => "v2.0"
	}
	s.source_files = "FHSTwitterEngine/*.{h,m}"
	s.requires_arc = true
	s.platform = :ios
end
