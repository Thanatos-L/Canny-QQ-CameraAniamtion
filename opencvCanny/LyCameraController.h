//
//  CameraController.h
//  opencvCanny
//
//  Created by 李龑 on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
@protocol LyCameraControllerDelegate<NSObject>
//- (void)cameraFocusStatuChange:(BOOL)isStart;
//- (void)cameraTorchModeChange:(BOOL)isLightsOn;
- (void)cameraContrllerFinishSetCamera;
@end
@interface LyCameraController : NSObject
@property (nonatomic, strong , readwrite) AVCaptureSession *avCaptureSession;
@property (nonatomic, strong , readwrite) AVCaptureDevice *avCaptureDevice;
@property (nonatomic, weak) id <AVCaptureVideoDataOutputSampleBufferDelegate> bufferDelegate;
@property (nonatomic, weak) id <LyCameraControllerDelegate> cameraDelegate;

- (void)prepareCaptureSession;
- (void)startCapture;
- (void)pauseCapture;
@end

NS_ASSUME_NONNULL_END
