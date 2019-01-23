#
# Be sure to run `pod lib lint BuggyEngine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BuggyEngine'
  s.version          = '0.1.5'
  s.summary          = 'BuggyEngine for IBB'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
	BuggyEngine用于小强App通过蓝牙与硬件建立连接并通讯
                       DESC

  s.homepage         = 'https://github.com/zidong0822/BuggyEngine'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zidong0822' => 'hehongwei@microduino.cc' }
  s.source           = { :git => 'https://github.com/zidong0822/BuggyEngine.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'
  s.swift_version = '4.2'

  s.source_files = 'Classes/*'
  
  # s.resource_bundles = {
  #   'BuggyEngine' => ['BuggyEngine/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
    s.dependency 'PromiseKit', '~> 6.0'
    s.dependency 'WKWebViewJavascriptBridge', '~> 1.2.0'
end
