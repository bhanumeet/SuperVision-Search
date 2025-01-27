platform :ios, '15.5'
use_frameworks!

project 'VisionExample.xcodeproj'

pod 'GoogleMLKit/TextRecognition', '7.0.0'
pod 'GoogleMLKit/TextRecognitionChinese', '7.0.0'
pod 'GoogleMLKit/TextRecognitionDevanagari', '7.0.0'
pod 'GoogleMLKit/TextRecognitionJapanese', '7.0.0'
pod 'GoogleMLKit/TextRecognitionKorean', '7.0.0'

target 'VisionExample' do
end

target 'VisionExampleObjC' do
end

post_install do |installer|
  installer.aggregate_targets.each do |target|
    target.xcconfigs.each do |variant, xcconfig|
      xcconfig_path = target.client_root + target.xcconfig_relative_path(variant)
      IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
    end
  end
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
         end
    end
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if config.base_configuration_reference.is_a? Xcodeproj::Project::Object::PBXFileReference
        xcconfig_path = config.base_configuration_reference.real_path
        IO.write(xcconfig_path, IO.read(xcconfig_path).gsub("DT_TOOLCHAIN_DIR", "TOOLCHAIN_DIR"))
      end
    end
  end
end