Pod::Spec.new do |s|
  s.name             = 'Birdsong'
  s.version          = '0.6.1'
  s.summary          = 'WebSockets client for Phoenix Channels.'
  s.homepage         = 'https://github.com/sjrmanning/Birdsong'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Simon Manning' => 'https://github.com/sjrmanning' }
  s.social_media_url = 'https://twitter.com/sjrmanning'
  s.source           = { :git => 'https://github.com/sjrmanning/Birdsong.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.source_files = 'Source/**/*'
  s.dependency 'Starscream', '3.1.0'
end
