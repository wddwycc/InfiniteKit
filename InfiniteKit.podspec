#
# Be sure to run `pod lib lint InfiniteKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'InfiniteKit'
  s.version          = '0.1.1'
  s.swift_version    = '4.2'
  s.summary          = 'declarative infinite data flow'
  s.description      = <<-DESC
declarative infinite data flow
                       DESC

  s.homepage         = 'https://github.com/wddwycc/InfiniteKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wddwycc' => 'wddwyss@gmail.com' }
  s.source           = { :git => 'https://github.com/wddwycc/InfiniteKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/wddwycc'

  s.ios.deployment_target = '10.0'

  s.source_files = 'src/**/*'

  s.dependency 'RxSwift', '~> 4.3'
  s.dependency 'RxCocoa', '~> 4.3'
  s.dependency 'RxDataSources', '~> 3.0'
  s.dependency 'RxSwiftExt', '~> 3.0'

end
