#
# Be sure to run `pod lib lint Sesame.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Sesame'
  s.version          = '0.1.0'
  s.summary          = 'Sesame is a framework for reinforcing app open behaviors.'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.homepage         = 'https://github.com/BoundlessAI/sesame-sdk-ios'
  s.social_media_url = 'https://twitter.com/BoundlessAI'
  s.author           = { 'BoundlessMind' => 'team@boundless.ai' }
  s.source           = { :git => 'https://github.com/BoundlessAI/sesame-sdk-ios', :tag => s.version.to_s }
  s.platform         = :ios
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'
  s.public_header_files = 'Pod/Classes/**/*.h'
  s.source_files = 'Sesame/Classes/**/*'
  s.resource_bundles = { 'Sesame' => ['Sesame/Assets/*.{png}'] }
  s.resources = 'Sesame/Assets/*.xcdatamodeld'
  s.frameworks = 'Foundation', 'UIKit', 'CoreData'
end
