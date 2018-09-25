Pod::Spec.new do |s|
    s.name                      = 'Sesame'
    s.version                   = '0.1.0'
    s.summary                   = 'Sesame is a framework for reinforcing app open behaviors.'
    s.license                   = { :type => 'MIT', :file => 'LICENSE' }
    s.homepage                  = 'https://github.com/BoundlessAI/sesame-sdk-ios'
    s.social_media_url          = 'https://twitter.com/BoundlessAI'
    s.author                    = { 'BoundlessAI' => 'team@boundless.ai' }
    s.source                    = { :git => 'https://github.com/BoundlessAI/sesame-sdk-ios', :tag => s.version.to_s }
    s.platform                  = :ios
    s.ios.deployment_target     = '8.0'
    s.swift_version             = '4.2'
    s.source_files              = 'Sesame/Classes/**/*.swift'
    s.resource_bundles          = { 'Sesame' => ['Sesame/Assets/*.png'] }
    s.resources                 = 'Sesame/Assets/*.xcdatamodeld'
    s.frameworks                = 'Foundation', 'UIKit', 'CoreData'
end
