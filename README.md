# SuperVision Search


**SuperVision Search** is an advanced iOS accessibility application that combines real-time text recognition with intelligent search capabilities. Designed to assist users in finding specific text within their environment, the app provides audio feedback, voice commands, and comprehensive text detection features.

## 🌟 Key Features

### 📱 Real-Time Text Detection
- **Live Camera Feed**: Continuously scans text through your device's camera
- **Instant Recognition**: Uses Google's ML Kit for accurate text recognition
- **Audio Feedback**: Plays a distinctive "beep" sound when target text is detected
- **Visual Highlighting**: Green overlay boxes highlight detected text in real-time
- **Metal Detector Experience**: Audio intensity increases as you get closer to target text

### 📸 Image Text Recognition
- **Photo Capture**: Take snapshots for detailed text analysis
- **Comprehensive Search**: Search through captured images with advanced highlighting
- **Multiple Instance Detection**: Find and navigate between multiple occurrences of search terms
- **Zoom and Pan**: Detailed image exploration with pinch-to-zoom and pan gestures
- **Auto-Rotation**: Intelligent text angle detection and image correction

### 🎙️ Voice Integration
- **Speech-to-Text**: Dictate search terms using your voice
- **Text-to-Speech**: Audio announcements of search results and status
- **Multi-Language Support**: Supports system language settings for both input and output
- **Audio Cues**: Distinctive "ding" and "dong" sounds for mic activation/deactivation

### 🔍 Advanced Search Capabilities
- **Fuzzy Matching**: Find text even with slight variations or OCR errors
- **Multi-Word Search**: Search for complete phrases and adjacent word combinations
- **Levenshtein Distance**: Intelligent matching algorithm for improved accuracy
- **Case-Insensitive Search**: Find text regardless of capitalization

### 🌐 Accessibility Features
- **VoiceOver Compatible**: Full accessibility label support
- **Audio Feedback**: Comprehensive voice announcements
- **Large Touch Targets**: Easy-to-use interface for users with motor difficulties
- **High Contrast UI**: Clear visual design for better visibility

## 🚀 Getting Started

### Prerequisites
- iOS 13.0 or later
- iPhone with camera
- Microphone access (for voice commands)
- Speech recognition permissions

### Installation
1. Clone this repository
2. Open `SuperVisionSearch.xcodeproj` in Xcode
3. Install dependencies (ML Kit, Speech Framework)
4. Open the newly created workspace created 
5. Build and run on your iOS device

### Required Permissions
The app requires the following permissions:
- **Camera Access**: For real-time text detection and photo capture
- **Microphone Access**: For voice command functionality
- **Speech Recognition**: For converting speech to text

## 📖 How to Use

### Basic Operation
1. **Launch the App**: Open SuperVision Search
2. **Enter Search Term**: Type your search term or use voice input
3. **Start Scanning**: Press and hold the scan button to begin real-time detection
4. **Listen for Beeps**: The app will beep when your target text is detected
5. **Take Photos**: Tap the camera button to capture and analyze images

### Real-Time Detection Mode
- **Press and Hold**: The scan button to activate real-time detection
- **Audio Feedback**: Listen for beep sounds indicating text detection
- **Visual Cues**: Watch for green highlight boxes around detected text
- **Release to Capture**: Release the scan button to take a snapshot

### Image Analysis Mode
- **Capture Photo**: Use the camera button to take a snapshot
- **Review Results**: View highlighted search results
- **Navigate Matches**: Use previous/next buttons to move between instances
- **Zoom In**: Tap the zoom button or use pinch gestures for closer inspection

### Voice Commands
1. **Activate Microphone**: Tap the microphone button
2. **Speak Clearly**: Dictate your search term
3. **Automatic Processing**: The app processes your speech and begins searching
4. **Audio Confirmation**: Hear confirmation of your search term

## 🎛️ Interface Elements

### Main Screen Controls
- **🔍 Search Bar**: Manual text input with real-time suggestions
- **🎤 Microphone Button**: Voice input activation
- **📷 Camera Button**: Instant photo capture
- **🔦 Scan Button**: Real-time detection mode (press and hold)
- **🔦 Torch Button**: Camera flash toggle
- **📊 Zoom Slider**: Camera zoom control (1x to 5x)
- **⚙️ Settings Button**: Access help and information

### Image Analysis Screen
- **⬅️ Previous/Next Buttons**: Navigate between found instances
- **🔍 Zoom In Button**: Focus on detected text
- **↩️ Back Button**: Return to camera mode
- **📝 Search Bar**: Modify search terms on the fly
- **🎤 Voice Input**: Update search via speech

## 🔧 Technical Features

### Text Recognition Engine
- **Google ML Kit Integration**: State-of-the-art text recognition
- **Multi-Language Support**: Automatic language detection
- **Angle Correction**: Automatic image rotation for optimal OCR
- **Real-Time Processing**: Efficient camera buffer processing

### Audio System
- **Multiple Sound Types**:
  - `ding.mp3`: Microphone activation
  - `dong.mp3`: Microphone deactivation
  - `beep.mp3`: Target text detection
  - `sonar.mp3`: Real-time scanning audio
  - `found.mp3`: Success confirmation

### Search Algorithms
- **Fuzzy Matching**: Levenshtein distance calculation
- **Word Boundary Detection**: Precise word matching
- **Multi-Term Search**: Adjacent word detection
- **Regular Expression Support**: Pattern-based searching

## 🌍 Language Support

SuperVision Search adapts to your device's language settings:

### Supported Languages
- **Speech Recognition**: Based on device locale settings
- **Text-to-Speech**: Uses system voice synthesis
- **UI Localization**: Supports internationalization keys
- **OCR Recognition**: ML Kit's comprehensive language support

### Localization Keys
The app includes localized strings for:
- Search prompts and confirmations
- Error messages and alerts
- Button labels and descriptions
- Accessibility announcements

## 🔧 Configuration Options

### Camera Settings
- **Zoom Range**: 1x to 5x digital zoom
- **Flash Control**: Manual torch on/off
- **Session Presets**: High-quality capture settings
- **Auto-Focus**: Continuous focusing for optimal text clarity

### Audio Settings
- **Voice Feedback**: Customizable speech synthesis
- **Sound Effects**: Individual audio cue controls
- **Volume Mixing**: Balanced audio session management
- **Bluetooth Support**: Compatible with external audio devices

### Recognition Parameters
- **Fuzzy Threshold**: Adjustable matching sensitivity
- **Debounce Timer**: Prevents excessive beeping
- **Processing Frequency**: Real-time analysis rate
- **Confidence Levels**: OCR accuracy thresholds

## 🛠️ Architecture Overview

### Core Components
```
SuperVision Search/
├── ViewController.swift        # Main camera interface
├── SnapshotViewController.swift # Image analysis screen  
├── InfoViewController.swift    # Help and information
└── UIUtilities.swift          # Vision processing utilities
```

### Key Technologies
- **AVFoundation**: Camera capture and audio processing
- **Speech Framework**: Voice recognition and synthesis
- **ML Kit Text Recognition**: Google's text detection API
- **Core Animation**: Visual effects and highlighting
- **Auto Layout**: Responsive UI design

### Design Patterns
- **Delegate Pattern**: Text field and camera delegates
- **Observer Pattern**: Notification center for events
- **MVC Architecture**: Clear separation of concerns
- **Protocol Extensions**: Modular functionality

## 🎯 Use Cases

### Educational Applications
- **Reading Assistance**: Help users locate specific words in textbooks
- **Language Learning**: Practice text recognition in foreign languages
- **Study Aid**: Quickly find key terms in documents

### Accessibility Support
- **Visual Impairment**: Audio feedback for text location
- **Motor Difficulties**: Large button interfaces and voice control
- **Learning Disabilities**: Multi-modal input and feedback

### Professional Uses
- **Document Scanning**: Quick text location in physical documents
- **Inventory Management**: Find product codes and labels
- **Quality Assurance**: Verify text placement and accuracy

## ⚠️ Troubleshooting

### Common Issues

**Camera Not Working**
- Ensure camera permissions are granted
- Check for hardware issues
- Restart the app if camera feed freezes

**Voice Recognition Errors**
- Verify microphone permissions
- Check network connection for speech processing
- Speak clearly and avoid background noise

**Text Not Detected**
- Ensure adequate lighting
- Hold device steady for better focus
- Try adjusting zoom for optimal text size

**Audio Feedback Issues**
- Check device volume settings
- Ensure audio session permissions
- Test with headphones if speaker problems persist


### Development Setup
```bash
# Clone the repository
git clone https://github.com/username/supervision-search.git

# Open in Xcode
open SuperVisionSearch.xcodeproj

# Install dependencies via CocoaPods
pod install
```
