platform :osx, '12.0'
use_frameworks!
inhibit_all_warnings!

target 'Thor' do
  pod 'SwiftLint'
  pod 'MASShortcut'
  pod 'Sparkle'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
