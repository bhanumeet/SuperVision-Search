platform :ios, '15.5'
use_frameworks!

# Define the project
project 'SuperVisionSearch.xcodeproj'

# ML Kit dependencies
target 'SuperVisionSearch' do
  pod 'GoogleMLKit/TextRecognition', '7.0.0'
  pod 'GoogleMLKit/TextRecognitionChinese', '7.0.0'
  pod 'GoogleMLKit/TextRecognitionDevanagari', '7.0.0'
  pod 'GoogleMLKit/TextRecognitionJapanese', '7.0.0'
  pod 'GoogleMLKit/TextRecognitionKorean', '7.0.0'
end

# Post-install script to fix potential deployment target issues and avoid warnings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Set the deployment target to avoid warnings
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
    end
  end
end
