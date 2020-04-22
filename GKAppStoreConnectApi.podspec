Pod::Spec.new do |s|
  s.name        = "GKAppStoreConnectApi"
  s.version     = "1.0.0"
  s.summary     = "GKAppStoreConnectApi provides a way to work with the App Store Connect from your app"
  s.homepage    = "https://github.com/Gikken-UG/GKAppStoreConnectApi"
  s.license     = { :type => "MIT" }
  s.authors     = { "liakhandrii" => "andrew@gikken.co"}

  s.requires_arc = true
  s.swift_version = "5.0"
  s.osx.deployment_target = "10.13"
  s.ios.deployment_target = "11.0"
  s.watchos.deployment_target = "5.0"
  s.tvos.deployment_target = "11.0"
  s.source   = { :git => "https://github.com/Gikken-UG/GKAppStoreConnectApi", :tag => s.version }
  s.source_files = "Source/**/*"
end
