#import <Foundation/Foundation.h>


#import <MLKitTextRecognitionCommon/MLKCommonTextRecognizerOptions.h>

NS_ASSUME_NONNULL_BEGIN

/** Configurations for a text recognizer for Devanagari and Latin-based languages. */
NS_SWIFT_NAME(DevanagariTextRecognizerOptions)
@interface MLKDevanagariTextRecognizerOptions : MLKCommonTextRecognizerOptions

/** Initializes a `DevanagariTextRecognizerOptions` instance with the default values. */
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
