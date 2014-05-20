Pod::Spec.new do |spec|
	spec.name = "FHSTwitterEngine"
	spec.version = "2.0"
	spec.summary = "Twitter API for Cocoa developers"
	spec.homepage = "https://github.com/fhsjaagshs/FHSTwitterEngine"	
	spec.license = { :type => "MIT", :file => "LICENSE" }
	spec.authors = { "Nathaniel Symer" => "nate@natesymer.com", "Daniel Khamsing" => "dkhamsing8@gmail.com" }
	spec.source = {
		:git => "https://github.com/fhsjaagshs/FHSTwitterEngine.git",
		:tag => "v2.0"
	}
	spec.source_files = "FHSTwitterEngine/*.{h,m}"
	spec.requires_arc = true
	spec.platform = :ios
	spec.ios.frameworks = 'Accounts', 'Social'	
end
