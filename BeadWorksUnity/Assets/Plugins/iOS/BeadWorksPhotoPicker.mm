#import "BeadWorksPhotoPicker.h"
#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>

// Provided by Unity's iOS runtime (UnityAppController.h).
extern UIViewController *UnityGetGLViewController(void);
extern "C" void UnitySendMessage(const char *className, const char *methodName, const char *message);

// PHPicker frequently returns images with a non-"up" EXIF orientation (e.g. portrait
// photos captured with the phone rotated). Redrawing into a fresh bitmap context bakes
// the orientation into the pixel data so the PNG we hand to Unity displays right-side up.
static UIImage *BeadWorksNormalizedOrientation(UIImage *image)
{
    if (image == nil || image.imageOrientation == UIImageOrientationUp)
    {
        return image;
    }

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.scale = image.scale;
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
        [image drawInRect:(CGRect){CGPointZero, image.size}];
    }];
}

@interface BeadWorksPhotoPickerDelegate : NSObject <PHPickerViewControllerDelegate>
@property(nonatomic, copy) NSString *callbackGameObject;
@end

@implementation BeadWorksPhotoPickerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results
{
    NSString *gameObject = self.callbackGameObject;
    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0)
    {
        UnitySendMessage([gameObject UTF8String], "OnNativePhotoPickCancelled", "");
        return;
    }

    NSItemProvider *provider = results.firstObject.itemProvider;
    if (![provider canLoadObjectOfClass:[UIImage class]])
    {
        UnitySendMessage([gameObject UTF8String], "OnNativePhotoPickFailed", "Unsupported image type");
        return;
    }

    [provider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading> _Nullable object, NSError *_Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil || object == nil)
            {
                NSString *message = error != nil ? error.localizedDescription : @"Failed to load image";
                UnitySendMessage([gameObject UTF8String], "OnNativePhotoPickFailed", [message UTF8String]);
                return;
            }

            UIImage *image = BeadWorksNormalizedOrientation((UIImage *)object);
            NSData *pngData = UIImagePNGRepresentation(image);
            if (pngData == nil)
            {
                UnitySendMessage([gameObject UTF8String], "OnNativePhotoPickFailed", "Failed to encode image");
                return;
            }

            NSString *fileName = [NSString stringWithFormat:@"beadworks_import_%.0f.png", [[NSDate date] timeIntervalSince1970] * 1000.0];
            NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

            NSError *writeError = nil;
            if (![pngData writeToFile:filePath options:NSDataWritingAtomic error:&writeError])
            {
                NSString *message = writeError != nil ? writeError.localizedDescription : @"Failed to save image";
                UnitySendMessage([gameObject UTF8String], "OnNativePhotoPickFailed", [message UTF8String]);
                return;
            }

            UnitySendMessage([gameObject UTF8String], "OnNativePhotoPicked", [filePath UTF8String]);
        });
    }];
}

@end

// Retained for the lifetime of a single picker presentation.
static BeadWorksPhotoPickerDelegate *_beadWorksActivePickerDelegate = nil;

void BeadWorks_PresentPhotoPicker(const char *gameObjectName)
{
    NSString *gameObject = [NSString stringWithUTF8String:gameObjectName];

    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.filter = [PHPickerFilter imagesFilter];
    config.selectionLimit = 1;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];

    BeadWorksPhotoPickerDelegate *delegate = [[BeadWorksPhotoPickerDelegate alloc] init];
    delegate.callbackGameObject = gameObject;
    _beadWorksActivePickerDelegate = delegate;
    picker.delegate = delegate;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = UnityGetGLViewController();
        [root presentViewController:picker animated:YES completion:nil];
    });
}

@interface BeadWorksSaveImageDelegate : NSObject
@property(nonatomic, copy) NSString *callbackGameObject;
@end

// Retained for the lifetime of a single save operation. Declared ahead of the
// @implementation below since the delegate clears it on completion.
static BeadWorksSaveImageDelegate *_beadWorksActiveSaveDelegate = nil;

@implementation BeadWorksSaveImageDelegate

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    NSString *gameObject = self.callbackGameObject;
    if (error != nil)
    {
        UnitySendMessage([gameObject UTF8String], "OnNativeSaveToPhotosFailed", [error.localizedDescription UTF8String]);
    }
    else
    {
        UnitySendMessage([gameObject UTF8String], "OnNativeSaveToPhotosSucceeded", "");
    }

    _beadWorksActiveSaveDelegate = nil;
}

@end

void BeadWorks_SaveImageToPhotos(const char *pngFilePath, const char *gameObjectName)
{
    NSString *path = [NSString stringWithUTF8String:pngFilePath];
    NSString *gameObject = [NSString stringWithUTF8String:gameObjectName];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if (image == nil)
    {
        NSLog(@"[BeadWorks] SaveImageToPhotos: failed to load image at %@", path);
        UnitySendMessage([gameObject UTF8String], "OnNativeSaveToPhotosFailed", "Failed to load image");
        return;
    }

    BeadWorksSaveImageDelegate *delegate = [[BeadWorksSaveImageDelegate alloc] init];
    delegate.callbackGameObject = gameObject;
    _beadWorksActiveSaveDelegate = delegate;

    UIImageWriteToSavedPhotosAlbum(image, delegate, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}
