//
//  CannyHelper.h
//  opencvCanny
//
//  Created by 李龑 on 2019/5/21.
//  Copyright © 2019 baidu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface CannyHelper : NSObject
@property (nonatomic, assign) float lowThreshold;

- (UIImage *)processImage:(UIImage *)image;
- (UIImage *)processSampleBuffer:(CMSampleBufferRef)buffer;
- (void)setupBackground:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
