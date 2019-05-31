//
//  CameraController.m
//  opencvCanny
//
//  Created by 李龑 on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

#import "LyCameraController.h"

@interface LyCameraController()
@property (nonatomic, strong) AVCaptureDeviceInput *avCaptureVideoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *avCaptureVideoDataOutput;

//二维码判断 liuq+
@property (nonatomic,strong) AVCaptureMetadataOutput * output;
@property (nonatomic, weak) id<AVCaptureMetadataOutputObjectsDelegate> metadataDelegate;

// add by xhc
@property (nonatomic) dispatch_queue_t sampleBufferCallbackQueue;
@property (nonatomic) dispatch_queue_t sessionQueue;

@property (nonatomic, assign) BOOL running;
@end
@implementation LyCameraController

- (void)setup {
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == AVCaptureDevicePositionFront) {
             self.avCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        }
    }
    _sampleBufferCallbackQueue = dispatch_queue_create("com.baidu.mms.buffer", DISPATCH_QUEUE_SERIAL);
//    _metedataQueue = dispatch_queue_create("com.baidu.mms.metadata", NULL);
    _sessionQueue = dispatch_queue_create("com.baidu.mms.image.session", DISPATCH_QUEUE_SERIAL);
}

- (void)prepareCaptureSession
{
    [self setup];
    // remove existing input
    if (self.avCaptureSession.inputs.count > 0) {
        AVCaptureInput* currentCameraInput = [self.avCaptureSession.inputs objectAtIndex:0];
        [self.avCaptureSession removeInput:currentCameraInput];
    }
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.avCaptureSession = session;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStart:)
                                                 name: AVCaptureSessionDidStartRunningNotification
                                               object: session];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onVideoStart:)
                                                 name: AVCaptureSessionInterruptionEndedNotification
                                               object: session];
    
    NSError *error = nil;
    
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_avCaptureDevice error:&error];
    self.avCaptureVideoInput = deviceInput;
    
    if (_avCaptureVideoInput == nil) {
        self.avCaptureDevice = nil;
        return ;
    }
    
    [_avCaptureSession beginConfiguration];
    
    // add videoDataOutPut
    [_avCaptureSession removeOutput:_avCaptureVideoDataOutput];
    
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [avCaptureVideoDataOutput setSampleBufferDelegate:_bufferDelegate queue:_sampleBufferCallbackQueue];
    
    self.avCaptureVideoDataOutput = avCaptureVideoDataOutput;
    
    if ([_avCaptureSession canAddOutput:_avCaptureVideoDataOutput])
    {
        [_avCaptureSession addOutput:_avCaptureVideoDataOutput];
    }
    _avCaptureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    
    if ([_avCaptureSession canAddInput:_avCaptureVideoInput]) {
        [_avCaptureSession addInput:_avCaptureVideoInput];
    } else {
        return ;
    }
    AVCaptureConnection *connection = [_avCaptureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection && [connection isVideoOrientationSupported]) {
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    
    
    // 设置设备支持自动对焦，自动曝光和自动白平衡，提高拍摄效果
    /*if ([_avCaptureDevice lockForConfiguration:&error])
     {
     if ([_avCaptureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
     {
     if ([_avCaptureDevice isFocusPointOfInterestSupported])
     {
     // 设置对焦点为中心位置
     CGPoint autofocusPoint = CGPointMake(AUTO_FOCUS_POINT_X, AUTO_FOCUS_POINT_Y);
     [_avCaptureDevice setFocusPointOfInterest:autofocusPoint];
     }
     
     [_avCaptureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
     }
     
     if ([_avCaptureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
     [_avCaptureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
     
     if ([_avCaptureDevice isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance])
     [_avCaptureDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
     
     [_avCaptureDevice unlockForConfiguration];
     }*/
    

    [_avCaptureSession commitConfiguration];
    
    return ;
}



#pragma mark - capture control methods

- (void)startCapture
{
    dispatch_async(self.sessionQueue, ^{
        if (self.avCaptureSession) {
            if (!self.avCaptureSession.running && self.avCaptureVideoInput) {
                [self.avCaptureSession startRunning];
                if ([self->_cameraDelegate respondsToSelector:@selector(cameraContrllerFinishSetCamera)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->_cameraDelegate cameraContrllerFinishSetCamera];
                    });
                }
            }
        }
    });
}

- (void)pauseCapture
{
    dispatch_async(self.sessionQueue, ^{
        if (self.avCaptureSession && self.avCaptureVideoInput) {
            [self.avCaptureSession stopRunning];
            self->_running = NO;
        }
    });
}

- (void)onVideoStart: (NSNotification*) note
{
    if(_running)
        return;
    _running = YES;
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO andisManualFocus:NO];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange andisManualFocus:(BOOL) isManual
{
    
    AVCaptureDevice *device = _avCaptureDevice;
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
            [device setFocusMode:focusMode];
            [device setFocusPointOfInterest:point];
        }
        if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:exposureMode];
            [device setExposurePointOfInterest:point];
        }
        [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
        [device unlockForConfiguration];
    }
    else {
        NSLog(@"%@", error);
    }
}

- (void)stop
{
    [_avCaptureSession stopRunning];
    
    if(_avCaptureSession.inputs.count > 0) {
        AVCaptureInput* input = [_avCaptureSession.inputs objectAtIndex:0];
        [_avCaptureSession removeInput:input];
    }
    for (int i = 0; i < _avCaptureSession.outputs.count; i++) {
        AVCaptureVideoDataOutput* output = [_avCaptureSession.outputs objectAtIndex:i];
        [_avCaptureSession removeOutput:output];
    }
}

- (void)stopCapture
{
    [_avCaptureVideoDataOutput setSampleBufferDelegate:nil queue:nil];
    [self stop];
    self.avCaptureVideoDataOutput = nil;
    self.avCaptureVideoInput = nil;
    self.avCaptureSession = nil;
    self.avCaptureDevice = nil;
}

@end
