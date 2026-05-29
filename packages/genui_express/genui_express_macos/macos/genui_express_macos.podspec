#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint genui_express_macos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'genui_express_macos'
  s.version          = '0.1.0'
  s.summary          = 'A macOS-specific implementation of the genui_express plugin utilizing Apple Intelligence Foundation Models.'
  s.description      = <<-DESC
A macOS-specific implementation of the genui_express plugin utilizing Apple Intelligence Foundation Models.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'genui_express_macos/Sources/genui_express_macos/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'genui_express_macos_privacy' => ['genui_express_macos/Sources/genui_express_macos/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '15.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(SDKROOT)/System/Library/PrivateFrameworks"'
  }
  s.swift_version = '5.0'
end
