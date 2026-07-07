#ifndef BeadWorksPhotoPicker_h
#define BeadWorksPhotoPicker_h

#ifdef __cplusplus
extern "C" {
#endif

/// Presents a PHPickerViewController limited to a single image.
/// Results are delivered asynchronously via UnitySendMessage to the GameObject
/// named `gameObjectName`, calling one of:
///   - OnNativePhotoPicked(string pngFilePath)
///   - OnNativePhotoPickCancelled(string _)
///   - OnNativePhotoPickFailed(string message)
void BeadWorks_PresentPhotoPicker(const char *gameObjectName);

/// Saves a PNG file at `pngFilePath` to the user's Photos library.
/// Result is delivered asynchronously via UnitySendMessage to the GameObject
/// named `gameObjectName`, calling one of:
///   - OnNativeSaveToPhotosSucceeded(string _)
///   - OnNativeSaveToPhotosFailed(string message)
void BeadWorks_SaveImageToPhotos(const char *pngFilePath, const char *gameObjectName);

#ifdef __cplusplus
}
#endif

#endif /* BeadWorksPhotoPicker_h */
