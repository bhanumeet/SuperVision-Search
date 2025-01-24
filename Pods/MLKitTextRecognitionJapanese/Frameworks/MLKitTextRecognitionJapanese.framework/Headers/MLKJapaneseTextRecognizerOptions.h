#import <Foundation/Foundation.h>


#import <MLKitTextRecognitionCommon/MLKCommonTextRecognizerOptions.h>

NS_ASSUME_NONNULL_BEGIN

/** Configurations for a text recognizer for Japanese and Latin-based languages. */
NS_SWIFT_NAME(JapaneseTextRecognizerOptions)
@interface MLKJapaneseTextRecognizerOptions : MLKCommonTextRecognizerOptions

/** Initializes a `JapaneseTextRecognizerOptions` instance with the default values. */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
